require 'json'

module PscbIntegration
  class CallbackController < ActionController::Base
    def payment_statuses
      encrypted_body = request.body.read
      log("PSCB payment_statuses encrypted params '#{encrypted_body.unpack('H*').first}'")

      body, is_demo_env = *decrypt(encrypted_body)
      log("PSCB payment_statuses binary params '#{body.unpack('H*').first}' demo_env=#{is_demo_env}")

      json = JSON.parse(body)
      log("PSCB payment_statuses params #{json.inspect}")

      response = json['payments'].map do |payment|
        confirmed = config.confirm_payment_callback.call(payment, is_demo_env)

        {
          orderId: payment['orderId'],
          action: confirmed ? 'CONFIRM' : 'REJECT'
        }
      end

      log("PSCB payment_statuses response #{response.inspect}")

      render json: { payments: response }
    end

    private

    def decrypt(encrypted_body)
      [
        client.decrypt(encrypted_body),
        false,
      ]
    rescue OpenSSL::Cipher::CipherError
      log("PSCB payment_statuses decryption with production key is failed, trying with demo key")

      [
        client.decrypt(encrypted_body, demo: true),
        true,
      ]
    end

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