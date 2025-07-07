FactoryBot.define do
  factory :migration_provider_relationship, class: "Migration::ProviderRelationship" do
    lead_provider { create(:migration_lead_provider) }
    delivery_partner { create(:migration_delivery_partner) }
    cohort { create(:migration_cohort) }
  end
end
