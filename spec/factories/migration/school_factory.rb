FactoryBot.define do
  factory :ecf_migration_school, class: "Migration::School" do
    sequence(:name) { |n| "School #{n}" }
    urn { Faker::Number.unique.number(digits: 6) }
    address_line1 { Faker::Address.street_address }
    postcode { Faker::Address.postcode }
    ukprn { Faker::Number.unique.number(digits: 5).to_s }
  end
end
