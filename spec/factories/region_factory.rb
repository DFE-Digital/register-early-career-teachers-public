FactoryBot.define do
  factory(:region) do
    sequence(:code) { |n| "XYZ#{n}" }
    districts { Faker::Address.city }
  end
end
