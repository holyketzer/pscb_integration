PscbIntegration::Engine.routes.draw do
  post 'pscb/payment_statuses' => 'callback#payment_statuses'
end
