FactoryBot.define do
  factory :migration_finance_adjustment, class: "Migration::FinanceAdjustment" do
    statement { FactoryBot.create(:migration_statement) }
    sequence(:payment_type) { |n| "Custom payment #{n}" }
    amount { 9.99 }
  end
end
