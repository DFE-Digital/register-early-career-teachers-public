FactoryBot.define do
  factory :migration_cpd_lead_provider, class: "Migration::CpdLeadProvider" do
    association :lead_provider, factory: :migration_lead_provider

    sequence(:name) { |n| "CPD Lead Provider #{n}" }
  end
end
