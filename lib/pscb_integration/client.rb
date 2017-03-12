require 'base64'
require 'faraday'
require 'faraday_middleware'

module PscbIntegration
  ApiError = Class.new(StandardError)
  UnknownPaymentError = Class.new(ApiError)

  class Client
    def initialize(settings)
      @settings = settings

      @client = Faraday.new(url: @settings[:host]) do |faraday|
        faraday.request  :json                    # form-encode POST params
        faraday.response :json

        if defined?(Rails)
          faraday.response :logger, Rails.logger, bodies: true
        end

        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end
    end

    def build_payment_url(message)
      json = message.to_json

      params = {
        marketPlace: @settings[:market_place],
        message: Base64.urlsafe_encode64(json),
        signature: signature(json),
      }

      @client.build_url('pay', params).to_s
    end

    def recurring_payment(prev_order_uid:, new_order_uid:, token:, amount:)
      body = {
        orderId: prev_order_uid,
        newOrderId: new_order_uid,
        marketPlace: @settings[:market_place],
        token: token,
        amount: amount,
      }.to_json

      res = @client.post('merchantApi/payRecurrent') do |request|
        request.headers['Signature'] = signature(body)
        request.body = body
      end

      handle_response(res)
    end

    def pull_order_status(order_uid)
      body = {
        orderId: order_uid,
        marketPlace: @settings[:market_place],
      }.to_json

      res = @client.post('merchantApi/checkPayment') do |request|
        request.headers['Signature'] = signature(body)
        request.body = body
      end

      handle_response(res)
    end

    def refund_order(order_uid)
      body = {
        orderId: order_uid,
        marketPlace: @settings[:market_place],
        partialRefund: false,
      }.to_json

      res = @client.post('merchantApi/refundPayment') do |request|
        request.headers['Signature'] = signature(body)
        request.body = body
      end

      handle_response(res)
    end

    def decrypt(encrypted)
      decipher = OpenSSL::Cipher::AES.new(128, :ECB)
      decipher.decrypt
      decipher.key = Digest::MD5.digest(@settings[:secret_key].to_s)

      plain = decipher.update(encrypted) + decipher.final
      plain.force_encoding('utf-8')
    end

    def encrypt(plain)
      cipher = OpenSSL::Cipher::AES.new(128, :ECB)
      cipher.encrypt
      cipher.key = Digest::MD5.digest(@settings[:secret_key].to_s)

      cipher.update(plain) + cipher.final
    end

    private

    def signature(str)
      Digest::SHA256.new.hexdigest(str + @settings[:secret_key].to_s)
    end

    def handle_response(res)
      body = res.body

      if body && body['status'] == 'STATUS_SUCCESS'
        body['payment']
      elsif body && body['errorCode'] == 'UNKNOWN_PAYMENT'
        raise UnknownPaymentError, "#{body}"
      else
        raise ApiError, "Payment system error #{body}"
      end
    end
  end
end