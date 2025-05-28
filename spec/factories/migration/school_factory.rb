FactoryBot.define do
  factory :ecf_migration_school, class: "Migration::School" do
    sequence(:name) { |n| "School #{n}" }
    urn { Faker::Number.unique.decimal_part(digits: 7) }
    address_line1 { Faker::Address.street_address }
    postcode { Faker::Address.postcode }
  end
end
