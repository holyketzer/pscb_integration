module GlobalSpecHelpers
  extend ActiveSupport::Concern

  included do
    before do
      PscbIntegration.instance_variable_set('@config', nil)
      PscbIntegration.instance_variable_set('@setup_block', nil)
    end
  end
end
