class API::DeliveryPartnerSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field :name
    field :created_at
    field(:api_updated_at, name: :updated_at)

    view :v3 do
      field(:cohort) do |delivery_partner, options|
        delivery_partner
          .active_lead_providers
          .select { it.lead_provider_id == options[:lead_provider_id] }
          .map { it.contract_period_year.to_s }
      end
    end

    view :v4 do
      field :new_field do
        "example"
      end
    end
  end

  identifier :api_id, name: :id
  field(:type) { "delivery-partner" }

  %i[v3 v4].each do |view|
    view view do
      association(:attributes, blueprint: AttributesSerializer, view:) do |delivery_partner|
        delivery_partner
      end
    end
  end
end
