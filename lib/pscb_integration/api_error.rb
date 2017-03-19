require 'pscb_integration/error_details'

module PscbIntegration
  class ApiError < StandardError
    ERROR_CODES = {
      'NOT_AUTHORIZED' => 'запрос не авторизован',
      'ILLEGAL_REQUEST' => 'некорректный запрос',
      'ILLEGAL_ARGUMENTS' => 'передан некорректный набор аргументов',
      'UNKNOWN_PAYMENT' => 'указанный платёж не обнаружен',
      'ILLEGAL_ACTION' => 'невозможно совершить требуемое действие',
      'ILLEGAL_PAYMENT_STATE' => 'невозможно совершить требуемое действие, т.к. платёж находится в неподходящем статусе',
      'FAILED' => 'невозможно совершить требуемое действие (причина в описании ошибки)',
      'REPEAT_REQUEST' => 'операция завершена с неопределённым результатом, требуется повторить запрос',
      'PROCESSING' => 'операция продолжается',
      'SERVER_ERROR' => 'произошла ошибка на сервере. При возникновении данной ошибки рекомендуется выполнить запрос состояния платежа, чтобы уточнить текущий статус платежа',
    }.freeze

    attr_reader :error_code, :body

    def initialize(error_code:, body:)
      @error_code = error_code
      @body = body
    end

    def to_s
      "#{error_code} #{ERROR_CODES[error_code]} #{body}"
    end

    def unknown_payment?
      'UNKNOWN_PAYMENT' == error_code
    end
  end

  class DetailedApiError < ApiError
    attr_reader :details

    def initialize(**params)
      @details = ErrorDetails.new(params)
    end
  end
end