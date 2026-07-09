class API::V4::DeliveryPartnerSerializer < API::V3::DeliveryPartnerSerializer
  def self.preload_associations(results)
    results.includes(active_lead_providers: :lead_provider)
  end

  class AttributesSerializer < API::V3::DeliveryPartnerSerializer::AttributesSerializer
    exclude :cohort

    field(:lead_providers) do |delivery_partner|
      delivery_partner.active_lead_providers.map { it.lead_provider.name }
    end

    field :new_field do
      "example"
    end
  end

  association :attributes, blueprint: AttributesSerializer do |delivery_partner|
    delivery_partner
  end
end
