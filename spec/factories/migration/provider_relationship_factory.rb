FactoryBot.define do
  factory :migration_provider_relationship, class: "Migration::ProviderRelationship" do
    lead_provider { FactoryBot.create(:migration_lead_provider) }
    delivery_partner { FactoryBot.create(:migration_delivery_partner) }
    cohort { FactoryBot.create(:migration_cohort) }
  end
end
