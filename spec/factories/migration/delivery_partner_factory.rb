FactoryBot.define do
  factory :migration_delivery_partner, class: "Migration::DeliveryPartner" do
    sequence(:name) { |n| "Migration Delivery Partner #{n}" }
  end
end
