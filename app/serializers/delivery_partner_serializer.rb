class DeliveryPartnerSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field :name
    field(:cohort) do |delivery_partner, options|
      lead_provider = options[:lead_provider]

      delivery_partner
        .lead_provider_delivery_partnerships
        .joins(:active_lead_provider)
        .where(active_lead_providers: { lead_provider_id: lead_provider.id })
        .pluck("active_lead_providers.contract_period_id")
    end

    field :created_at
    field(:api_updated_at, name: :updated_at)
  end

  identifier :api_id, name: :id
  field(:type) { "delivery-partner" }

  association :attributes, blueprint: AttributesSerializer do |delivery_partner|
    delivery_partner
  end
end
