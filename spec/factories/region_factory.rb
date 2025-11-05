FactoryBot.define do
  factory(:region) do
    sequence(:code) { |n| "XYZ#{n}" }
    districts do
      Array.new(rand(1..8)) { Faker::Address.city }
    end
  end
end
