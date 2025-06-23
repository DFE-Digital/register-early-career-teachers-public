FactoryBot.define do
  factory(:parity_check_request, class: "ParityCheck::Request") do
    association(:lead_provider)
    association(:run, factory: :parity_check_run)
    association(:endpoint, factory: :parity_check_endpoint)
  end
end
