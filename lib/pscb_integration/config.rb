module PscbIntegration
  class Config
    attr_accessor :host, :market_place, :secret_key, :update_payment_status

    def initialize(attrs = {})
      attrs.each do |name, value|
        public_send("#{name}=", value)
      end
    end
  end
end