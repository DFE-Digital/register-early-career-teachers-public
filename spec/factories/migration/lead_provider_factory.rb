FactoryBot.define do
  factory :migration_lead_provider, class: "Migration::LeadProvider" do
    sequence(:name) { |n| "Migration Lead Provider #{n}" }

    Mappers::LeadProviderMapper::DATA.each do |record|
      trait record.trait_name do
        name { record.name }
        cpd_lead_provider_id { record.cpd_lead_provider_id }
        id { record.id }

        before(:create) do
          FactoryBot.create(:migration_cpd_lead_provider, id: it.cpd_lead_provider_id)
        end
      end
    end

    trait :active do
      after(:create) do |lead_provider|
        lead_provider.cohorts << FactoryBot.create(:migration_cohort)
      end
    end
  end
end
