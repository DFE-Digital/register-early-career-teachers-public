FactoryBot.define do
  factory(:statement_adjustment, class: "Statement::Adjustment") do
    statement

    api_id { SecureRandom.uuid }
    sequence(:payment_type) { |n| "Payment #{n}" }
    amount { 100 }
  end
end
