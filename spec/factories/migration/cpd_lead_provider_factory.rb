FactoryBot.define do
  factory :migration_cpd_lead_provider, class: "Migration::CpdLeadProvider" do
    lead_provider { create(:migration_lead_provider) }

    sequence(:name) { |n| "CPD Lead Provider #{n}" }
  end
end
