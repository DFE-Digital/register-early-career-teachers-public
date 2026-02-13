FactoryBot.define do
  factory(:legacy_appropriate_body) do
    initialize_with do
      LegacyAppropriateBody.find_or_initialize_by(name:)
    end

    association :appropriate_body_period

    name { Faker::Company.name }
    dqt_id { Faker::Internet.uuid }
    body_type { "local_authority" }
  end
end
