require 'pscb_integration/version'
require 'pscb_integration/client'
require 'pscb_integration/config'
require 'pscb_integration/engine'

module PscbIntegration
  ConfigurationError = Class.new(StandardError)

  class << self
    attr_accessor :config

    def config
      @config ||= begin
        if @setup_block
          config = Config.new
          @setup_block.call(config)
          config
        else
          raise ConfigurationError
        end
      end
    end

    # Gets called within the initializer
    def setup(&block)
      @setup_block = block
    end
  end
end
