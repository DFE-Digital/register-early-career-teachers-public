FactoryBot.define do
  factory(:legacy_appropriate_body) do
    name { Faker::Company.name }
    dqt_id { Faker::Internet.uuid }
    appropriate_body_period { association :appropriate_body }
    body_type { "local_authority" }
  end
end
