class API::V4::DeliveryPartnerSerializer < API::V3::DeliveryPartnerSerializer
  class AttributesSerializer < API::V3::DeliveryPartnerSerializer::AttributesSerializer
    exclude :cohort

    field :new_field do
      "example"
    end
  end

  association :attributes, blueprint: AttributesSerializer do |delivery_partner|
    delivery_partner
  end
end
