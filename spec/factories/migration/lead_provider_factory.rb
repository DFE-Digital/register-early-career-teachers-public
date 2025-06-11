FactoryBot.define do
  factory :migration_lead_provider, class: "Migration::LeadProvider" do
    name  { Faker::Company.name }
  end
end
