module PscbIntegration
  class BaseApiError
    ERROR_CODES = {
      timeout: 'timeout error',
      connection_failed: 'connection failed error',
    }.freeze

    attr_reader :error_code

    def initialize(error_code)
      @error_code = error_code
    end

    def to_s
      ERROR_CODES[error_code]
    end

    def timeout?
      :timeout == error_code
    end

    def connection_failed?
      :connection_failed == error_code
    end

    def unknown_payment?
      false
    end
  end
end