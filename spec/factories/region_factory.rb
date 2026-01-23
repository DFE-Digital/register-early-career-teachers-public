FactoryBot.define do
  factory(:region) do
    initialize_with do
      Region.find_or_initialize_by(code:)
    end

    sequence(:code) { |n| "XYZ#{n}" }

    districts do
      Array.new(rand(1..8)) { Faker::Address.city }
    end
  end
end
