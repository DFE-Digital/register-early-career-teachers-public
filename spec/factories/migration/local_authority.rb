FactoryBot.define do
  factory :ecf_migration_local_authority, class: "Migration::LocalAuthority" do
    code { Faker::Number.unique.decimal_part.to_s }
    name { "Test local authority" }
  end
end
