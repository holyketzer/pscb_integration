module PscbIntegration
  class Config
    attr_accessor :host, :market_place, :secret_key, :demo_secret_key, :confirm_payment_callback,
      :timeout

    def initialize(attrs = {})
      attrs.each do |name, value|
        public_send("#{name}=", value)
      end

      self.timeout ||= 5
    end
  end
end
