require 'pscb_integration/version'
require 'pscb_integration/client'
require 'pscb_integration/config'
require 'pscb_integration/engine'

module PscbIntegration
  class << self
    attr_accessor :config

    def config
      @config ||= Config.new
    end

    # Gets called within the initializer
    def setup
      yield(config)
    end
  end
end
