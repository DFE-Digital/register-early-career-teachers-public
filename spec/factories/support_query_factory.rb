FactoryBot.define do
  factory(:support_query) do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    school_name { Faker::University.name }
    school_urn { Faker::Number.number(digits: 6) }
    message { Faker::Lorem.paragraph }

    trait :sent do
      state { :sent }
      zendesk_id { Random.rand(1_000_000..9_999_999) }
    end
  end
end
