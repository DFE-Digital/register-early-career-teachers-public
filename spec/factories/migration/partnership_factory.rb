FactoryBot.define do
  factory :migration_partnership, class: "Migration::Partnership" do
    lead_provider { FactoryBot.create(:migration_lead_provider) }
    delivery_partner { FactoryBot.create(:migration_delivery_partner) }
    cohort { FactoryBot.create(:migration_cohort) }
    school { FactoryBot.create(:ecf_migration_school) }
  end
end
