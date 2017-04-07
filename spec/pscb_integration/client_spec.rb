require 'addressable/uri'
require 'fear/rspec'

describe PscbIntegration::Client do
  let(:client) { described_class.new(config) }

  let(:secret_key) { '111111' }
  let(:host) { 'https://oosdemo.pscb.ru' }
  let(:market_place) { 25633032 }
  let(:amount) { 200.0 }

  let(:config) do
    PscbIntegration::Config.new(
      host: host,
      market_place: market_place,
      secret_key: secret_key,
    )
  end

  describe 'encryption' do
    let(:encrypted) { Base64.decode64('E/N15ExqrkpPzb8OAzc8eimNZHR601e42Mf6btmjER4=') }
    let(:plain) { 'HelloПривет' }
    let(:secret_key) { 'dragon' }

    describe '#decrypt' do
      subject { client.decrypt(encrypted) }

      it { is_expected.to eq plain }
    end

    describe '#encrypt' do
      subject { client.encrypt(plain) }

      it { is_expected.to eq encrypted }
    end
  end

  describe '#build_payment_url' do
    def message
      {
        nonce: 'random',
        customerAccount: 10,
        customerRating: 5,
        customerEmail: 'user@email.com',
        customerPhone: '+79001112233',
        orderId: '12345',
        details: 'Balance paymnet',
        amount: amount,
        paymentMethod: 'ac',
        recurrentable: true,
        data: {
          debug: 1,
        }
      }
    end

    subject { Addressable::URI.parse(client.build_payment_url(message)) }

    it do
      expect(subject.site).to eq host
      expect(subject.path).to eq '/pay'
      expect(subject.query_values).to include('marketPlace' => market_place.to_s)
      expect(subject.query_values).to include('message', 'signature')
    end
  end

  describe '#pull_order_status' do
    subject do
      VCR.use_cassette("pull_status_#{cassette}") do
        client.pull_order_status(order_id)
      end
    end

    context 'unknown payment' do
      let(:cassette) { 'unknown_payment' }
      let(:order_id) { 'unknown_id' }

      it do
        expect(subject).to be_left_of(PscbIntegration::ApiError)

        expect(subject.swap.map { |e| e.to_s }).to be_right_of(
          match(/unknown_payment/i)
        )
      end
    end

    context 'successefull payment' do
      let(:cassette) { 'successefull_payment' }
      let(:order_id) { '12345' }

      it do
        expect(subject).to be_right_of(
          include(
            'orderId' => order_id,
            'amount' => amount,
            'state' => 'end',
            'marketPlace' => market_place,
          )
        )
      end
    end

    context 'unsuccessefull payment' do
      let(:cassette) { 'unsuccessefull_payment' }
      let(:order_id) { '12346' }

      it do
        expect(subject).to be_right_of(
          include(
            'orderId' => order_id,
            'amount' => amount,
            'state' => 'err',
            'marketPlace' => market_place,
          )
        )
      end
    end
  end

  describe '#refund_order' do
    subject do
      VCR.use_cassette("refund_order_#{cassette}") do
        client.refund_order(order_id)
      end
    end

    context 'successefull payment' do
      let(:cassette) { 'successefull_payment' }
      let(:order_id) { '12347' }

      it do
        expect(subject).to be_right_of(
          include(
            'orderId' => order_id,
            'state' => 'end',
            'marketPlace' => market_place,
          )
        )

        expect(subject).to be_right_of(
          include('refunds')
        )
      end

      context 'failed payment' do
        let(:cassette) { 'failed_payment' }
        let(:order_id) { '12346' }

        it do
          expect(subject).to be_left_of(PscbIntegration::ApiError)

          expect(subject.swap.map { |e| e.to_s }).to be_right_of(
            match(/невозможно совершить требуемое действие/)
          )
        end
      end

      context 'refunded payment' do
        let(:cassette) { 'refunded_payment' }
        let(:order_id) { '12347' }

        it do
          expect(subject).to be_left_of(PscbIntegration::ApiError)

          expect(subject.swap.map { |e| e.to_s }).to be_right_of(
            match(/невозможно совершить требуемое действие/)
          )
        end
      end
    end
  end

  describe '#recurring_payment' do
    subject do
      VCR.use_cassette("recurring_payment_#{cassette}") do
        client.recurring_payment(
          prev_order_uid: prev_order_uid,
          new_order_uid: new_order_uid,
          token: token,
          amount: amount,
        )
      end
    end

    let(:amount) { 125.0 }
    let(:new_order_uid) { '23456' }

    context 'prev order is recurrentable' do
      let(:cassette) { 'prev_order_is_recurrentable' }
      let(:prev_order_uid) { '12345' }
      let(:token) { '13346679' }

      it do
        expect(subject).to be_right_of(
          include(
            'orderId' => new_order_uid,
            'amount' => amount,
            'state' => 'sent',
            'marketPlace' => market_place,
          )
        )
      end
    end

    context 'prev order is not recurrentable' do
      let(:cassette) { 'prev_order_is_not_recurrentable' }
      let(:prev_order_uid) { '12346' }
      let(:token) { '00000' }

      it do
        expect(subject).to be_left_of(PscbIntegration::ApiError)

        expect(subject.swap.map { |e| e.error_code }).to be_right_of('ILLEGAL_PAYMENT_STATE')
      end
    end
  end
end