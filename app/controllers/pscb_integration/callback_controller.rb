require 'json'

module PscbIntegration
  class CallbackController < ActionController::Base
    def payment_statuses
      encrypted_body = request.body.read
      log("PSCB payment_statuses encrypted params '#{encrypted_body.unpack('H*').first}'")

      body = client.decrypt(encrypted_body)
      log("PSCB payment_statuses binary params '#{body.unpack('H*').first}'")

      json = JSON.parse(body)
      log("PSCB payment_statuses params #{json.inspect}")

      response = json['payments'].map do |payment|
        {
          orderId: payment['orderId'],
          action: config.update_payment_status.call(payment)
        }
      end

      log("PSCB payment_statuses response #{response.inspect}")

      render json: { payments: response }
    end

    private

    def log(line)
      if defined?(Rails)
        Rails.logger.info(line)
      end
    end

    def client
      @client ||= Client.new
    end

    def config
      PscbIntegration.config
    end
  end
end