constraints -> { Rails.application.config.enable_notify_delivery_receipts } do
  namespace :notify do
    resource :delivery_receipts, only: :create
  end
end
