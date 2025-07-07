FactoryBot.define do
  factory :migration_partnership, class: "Migration::Partnership" do
    lead_provider { create(:migration_lead_provider) }
    delivery_partner { create(:migration_delivery_partner) }
    cohort { create(:migration_cohort) }
    school { create(:ecf_migration_school) }
  end
end
