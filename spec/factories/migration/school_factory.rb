FactoryBot.define do
  factory :ecf_migration_school, class: "Migration::School" do
    sequence(:name) { |n| "School #{n}" }
    urn { Faker::Number.unique.number(digits: 6) }
    address_line1 { Faker::Address.street_address }
    postcode { Faker::Address.postcode }
    ukprn { Faker::Number.unique.number(digits: 5).to_s }
    school_status_code { 1 }
    school_type_code { 1 }
    school_type_name { "Community school" }
  end
end
