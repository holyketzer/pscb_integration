require 'base64'
require 'faraday'
require 'faraday_middleware'
require 'fear'
require 'pscb_integration/base_api_error'
require 'pscb_integration/api_error'
require 'pscb_integration/extended_api_error'

module PscbIntegration
  class Client
    include Fear::Either::Mixin

    attr_reader :config

    def initialize(explicit_config = nil)
      @config = explicit_config || PscbIntegration.config

      @client = Faraday.new(url: config.host) do |faraday|
        faraday.request  :json                    # form-encode POST params
        faraday.response :json

        if defined?(Rails)
          faraday.response :logger, Rails.logger, bodies: true
        end

        faraday.adapter Faraday.default_adapter  # make requests with Net::HTTP
      end
    end

    def build_payment_url(message)
      json = message.to_json

      params = {
        marketPlace: config.market_place,
        message: Base64.urlsafe_encode64(json),
        signature: signature(json),
      }

      @client.build_url('pay', params).to_s
    end

    def recurring_payment(prev_order_uid:, new_order_uid:, token:, amount:)
      body = {
        orderId: prev_order_uid,
        newOrderId: new_order_uid,
        marketPlace: config.market_place,
        token: token,
        amount: amount,
      }.to_json

      handle_response(
        post('merchantApi/payRecurrent', body)
      )
    end

    def pull_order_status(order_uid)
      body = {
        orderId: order_uid,
        marketPlace: config.market_place,
      }.to_json

      handle_response(
        post('merchantApi/checkPayment', body)
      )
    end

    def refund_order(order_uid)
      body = {
        orderId: order_uid,
        marketPlace: config.market_place,
        partialRefund: false,
      }.to_json

      handle_response(
        post('merchantApi/refundPayment', body)
      )
    end

    def decrypt(encrypted, demo: false)
      secret_key = demo ? config.demo_secret_key : config.secret_key

      decipher = OpenSSL::Cipher::AES.new(128, :ECB)
      decipher.decrypt
      decipher.key = Digest::MD5.digest(secret_key.to_s)

      plain = decipher.update(encrypted) + decipher.final
      plain.force_encoding('utf-8')
    end

    def encrypt(plain)
      cipher = OpenSSL::Cipher::AES.new(128, :ECB)
      cipher.encrypt
      cipher.key = Digest::MD5.digest(config.secret_key.to_s)

      cipher.update(plain) + cipher.final
    end

    private

    def signature(str)
      Digest::SHA256.new.hexdigest(str + config.secret_key.to_s)
    end

    # @return [Either<Faraday::Response, BaseApiError>]
    def post(path, body)
      response = @client.post(path) do |request|
        request.headers['Signature'] = signature(body)
        request.body = body

        request.options.timeout = config.timeout
        request.options.open_timeout = config.timeout
      end

      Right(response.body)
    rescue Faraday::TimeoutError
      Left(BaseApiError.new(:timeout))
    rescue Faraday::Error::ConnectionFailed
      Left(BaseApiError.new(:connection_failed))
    end

    # @return [Either<Hash, BaseApiError>]
    def handle_response(response_body)
      response_body.flat_map do |body|
        if body && body['status'] == 'STATUS_SUCCESS'
          Right(body['payment'])
        elsif body && (error_code = body['errorCode'])
          Left(ApiError.new(error_code: error_code, body: body))
        elsif body && (error = body['paymentSystemError'] || body.dig('payment', 'lastError'))
          Left(
            ExtendedApiError.new(
              error_code: error['code'],
              error_sub_code: error['subCode'],
              details: error['details'],
              body: body,
            )
          )
        else
          Left(ApiError.new(error_code: 'Payment system error', body: body))
        end
      end
    end
  end
end
