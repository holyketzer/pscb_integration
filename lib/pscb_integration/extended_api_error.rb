module PscbIntegration
  class ExtendedApiError < ApiError
    ERROR_CODES = {
      0 => 'Платеж обработан успешно',
      1 => 'Платеж находится в обработке',
      2 => 'Платеж ожидает подтверждения одноразовым паролем',
      3 => 'Для завершения привязки рекуррентного платежа необходимо передать сумму, заблокированную на карте Клиента',
      -1 => 'Транзакция отвергнута ПЦ  Требуется анализ subCode',
      -2 => 'Транзакция отвергнута СИСТЕМОЙ  Требуется анализ subCode',
      -3 => 'Неверные параметры платежа, платеж не прошел проверку у поставщика услуги',
      -4 => 'Карта не привязана: возникает, если карта, с которой пытаются сделать оплату, не привязана к веб-кошельку или услуге, а это требуется, согласно настройке услуги',
      -5 => 'Неизвестная ошибка, транзакция отвергнута',
      -14 => 'Не верная SMS подтверждения платежа для Веб-кошелька',
      -15 => 'Рекуррентные платежи не поддерживаются',
      -16 => 'Некорректные параметры для рекуррентного платежа',
      -17 => 'Подпись не верна',
      -18 => 'Нарушение лимитов СИСТЕМЫ',
      -19 => 'Попытка фрода',
    }.freeze

    ERROR_SUB_CODES = {
      100 => 'Сервис недоступен',
      101 => 'Регламентные работы',
      102 => 'Недоступен шлюз в МПС',
      103 => 'Технический сбой при обработке платежа, пользователь пытался задвоить транзакцию (нажал F5 в браузере)',
      104 => 'Технический сбой при обработке платежа, разрушилась сессия на веб-сервере',
      105 => 'Не прошла валидация полей',
      106 => 'Не передан телефон (для услуги, оплачиваемой через веб-кошелек)',
      -20 => 'Expired transaction',
      -19 => 'Authentication failed',
      -17 => 'Access denied',
      -16 => 'Terminal is locked, please try again',
      -9 => 'Error in card expiration date field',
      -4 => 'Server is not responding',
      -3 => 'No or Invalid response received',
      -2 => 'Bad CGI request',
      0 => 'Approved',
      1 => 'Call your bank',
      3 => 'Invalid merchant',
      4 => 'Your card is restricted',
      5 => 'Transaction declined',
      6 => 'Error - retry',
      12 => 'Invalid transaction',
      13 => 'Invalid amount',
      14 => 'No such card',
      15 => 'No such card/issuer',
      19 => 'Re-enter transaction',
      20 => 'Invalid response',
      30 => 'Format error',
      41 => 'Lost card',
      43 => 'Stolen card',
      51 => 'Not sufficient funds',
      54 => 'Expired card',
      55 => 'Incorrect PIN',
      57 => 'Not permitted to client',
      58 => 'Not permitted to merchant',
      61 => 'Exceeds amount limit',
      62 => 'Restricted card',
      65 => 'Exceeds frequency limit',
      75 => 'PIN tries exceeded',
      78 => 'Reserved',
      82 => 'Time-out at issuer',
      89 => 'Authentication failure',
      91 => 'Issuer unavailable',
      93 => 'Violation of law',
      96 => 'System malfunction',
    }.freeze

    attr_reader :error_sub_code, :description

    def initialize(error_code:, error_sub_code:, description:, body:)
      super(error_code: error_code, body: body)
      @error_sub_code = error_sub_code
      @description = description
    end

    def to_s
      "#{description} #{ERROR_CODES[error_code]} #{ERROR_SUB_CODES[error_sub_code]} #{body}"
    end
  end
end