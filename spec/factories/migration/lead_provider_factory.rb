FactoryBot.define do
  factory :migration_lead_provider, class: "Migration::LeadProvider" do
    name  { Faker::Company.name }

    trait :active do
      after(:create) do |lead_provider|
        lead_provider.cohorts << FactoryBot.create(:migration_cohort)
      end
    end
  end
end
