class API::DeliveryPartnerSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field :name
    field :created_at
    field(:api_updated_at, name: :updated_at)
    field(:cohort) do |delivery_partner, options|
      delivery_partner
        .active_lead_providers
        .select { it.lead_provider_id == options[:lead_provider_id] }
        .map { it.contract_period_year.to_s }
    end
  end

  identifier :api_id, name: :id
  field(:type) { "delivery-partner" }

  association :attributes, blueprint: AttributesSerializer do |delivery_partner|
    delivery_partner
  end
end
