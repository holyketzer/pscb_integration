describe PscbIntegration::Client do
  let(:encrypted) { Base64.decode64("E/N15ExqrkpPzb8OAzc8eimNZHR601e42Mf6btmjER4=") }
  let(:plain) { 'HelloПривет' }
  let(:secret_key) { 'dragon' }

  let(:settings) { { secret_key: secret_key } }
  let(:client) { described_class.new(settings) }

  describe '#decrypt' do
    subject { client.decrypt(encrypted) }

    it { is_expected.to eq plain }
  end

  describe '#encrypt' do
    subject { client.encrypt(plain) }

    it { is_expected.to eq encrypted }
  end
end