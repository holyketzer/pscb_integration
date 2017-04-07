module ControllerSpecHelpers
  include Rack::Test::Methods

  extend ActiveSupport::Concern

  def app
    Rails.application
  end

  included do
    let(:json) { JSON.parse(last_response.body).deep_symbolize_keys }
    let(:status) { last_response.status }
    let(:data) { json[:data] }
  end
end
