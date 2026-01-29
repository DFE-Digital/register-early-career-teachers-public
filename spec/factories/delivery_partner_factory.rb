FactoryBot.define do
  factory(:delivery_partner) do
    sequence(:name) { |n| "Delivery Partner #{n}" }

    initialize_with do
      DeliveryPartner.find_or_initialize_by(name:)
    end
  end
end
