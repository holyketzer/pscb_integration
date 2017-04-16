describe PscbIntegration do
  it 'has a version number' do
    expect(PscbIntegration::VERSION).not_to be nil
  end

  describe '.config' do
    subject { described_class.config.market_place }

    context 'initialized' do
      before do
        described_class.setup do |config|
          config.market_place = '123'
        end
      end

      it { is_expected.to eq '123' }
    end

    context 'not initialized' do
      it { expect { subject }.to raise_error(described_class::ConfigurationError) }
    end
  end
end
