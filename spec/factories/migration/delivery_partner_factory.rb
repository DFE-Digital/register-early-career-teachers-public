FactoryBot.define do
  factory :migration_delivery_partner, class: "Migration::DeliveryPartner" do
    name  { Faker::Company.name }
  end
end
