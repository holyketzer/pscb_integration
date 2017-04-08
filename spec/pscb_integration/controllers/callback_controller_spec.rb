describe PscbIntegration::CallbackController, controller: true do
  describe '#payment_statuses' do
    before do
      PscbIntegration.setup do |config|
        config.host = 'https://oosdemo.pscb.ru'
        config.market_place = '25633032'
        config.secret_key = '111111'
        config.demo_secret_key = '000000'
        config.confirm_payment_callback = confirm_payment_callback
      end
    end

    subject do
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

    let(:confirm_payment_callback) do
      ->(payment, is_demo) do
        if is_demo
          raise StandardError.new('This is no demo env')
        else
          payment['orderId'] == 'succesefull'
        end
      end
    end

    context 'failed order' do
      let(:order_id) { 'failed' }

      it do
        subject
        expect(status).to eq 200
        expect(json[:payments]).to include(orderId: order_id, action: 'REJECT')
      end
    end

    context 'succesefull order' do
      let(:order_id) { 'succesefull' }

      it do
        subject
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
        subject
        expect(status).to eq 200
        expect(json[:payments]).to include(orderId: 'succesefull', action: 'CONFIRM')
        expect(json[:payments]).to include(orderId: 'failed', action: 'REJECT')
      end
    end

    context 'invalid secret_key' do
      let(:another_secret_key) { '12345678' }
      let(:config) { double(secret_key: another_secret_key) }

      before do
        allow(client).to receive(:config).and_return(config)
      end

      context 'unknown order' do
        let(:order_id) { 'unknown' }

        it do
          expect { subject }.to raise_error(OpenSSL::Cipher::CipherError)
        end
      end
    end

    context 'secret_key from demo env' do
      let(:demo_secret_key) { PscbIntegration.config.demo_secret_key }
      let(:config) { double(secret_key: demo_secret_key) }

      before do
        allow(client).to receive(:config).and_return(config)
      end

      context 'demo order' do
        let(:order_id) { 'demo' }

        it do
          expect { subject }.to raise_error(StandardError, /this is no demo env/i)
        end
      end
    end
  end
end