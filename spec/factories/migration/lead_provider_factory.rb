FactoryBot.define do
  factory :migration_lead_provider, class: "Migration::LeadProvider" do
    sequence(:name) { |n| "Migration Lead Provider #{n}" }

    trait :active do
      after(:create) do |lead_provider|
        lead_provider.cohorts << FactoryBot.create(:migration_cohort)
      end
    end
  end
end
