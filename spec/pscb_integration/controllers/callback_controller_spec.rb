describe PscbIntegration::CallbackController, controller: true do
  describe '#payment_statuses' do
    before do
      PscbIntegration.setup do |config|
        config.host = 'https://oosdemo.pscb.ru'
        config.market_place = '25633032'
        config.secret_key = '111111'
        config.update_payment_status = update_payment_status
      end

      header 'Content-Type', 'application/octet-stream'
      post '/integration_api/pscb/payment_statuses', body_binary
    end

    let(:client) { PscbIntegration::Client.new }
    let(:body_binary) { client.encrypt(body) }
    let(:body) { JSON.generate(payments: payments) }
    let(:payments) do
      [
        {
          orderId: order_id,
          paymentMethod: 'ac',
          state: 'sent',
        }
      ]
    end

    let(:update_payment_status) do
      ->(payment) { payment['orderId'] == 'succesefull' ? 'CONFIRM' : 'REJECT' }
    end

    context 'failed order' do
      let(:order_id) { 'failed' }

      it do
        expect(status).to eq 200
        expect(json[:payments]).to include(orderId: order_id, action: 'REJECT')
      end
    end

    context 'succesefull order' do
      let(:order_id) { 'succesefull' }

      it do
        expect(status).to eq 200
        expect(json[:payments]).to include(orderId: order_id, action: 'CONFIRM')
      end
    end

    context 'several orders' do
      let(:payments) do
        [
          {
            orderId: 'succesefull',
            paymentMethod: 'ac',
            state: 'sent',
          },
          {
            orderId: 'failed',
            paymentMethod: 'ac',
            state: 'sent',
          }
        ]
      end

      it do
        expect(status).to eq 200
        expect(json[:payments]).to include(orderId: 'succesefull', action: 'CONFIRM')
        expect(json[:payments]).to include(orderId: 'failed', action: 'REJECT')
      end
    end
  end
end