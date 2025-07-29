FactoryBot.define do
  factory(:delivery_partner) do
    sequence(:name) { |n| "#{Faker::University.name} Delivery Partner #{n}" }
  end
end
