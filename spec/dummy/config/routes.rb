Rails.application.routes.draw do
  namespace :integration_api do
    mount PscbIntegration::Engine => '/'
  end
end
