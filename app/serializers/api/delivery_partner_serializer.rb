class API::DeliveryPartnerSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field :name
    field :created_at
    field(:api_updated_at, name: :updated_at)
    field(:cohort) do |delivery_partner, options|
      lead_provider_metadata(delivery_partner:, options:).contract_period_years.map(&:to_s)
    end

    class << self
      def lead_provider_metadata(delivery_partner:, options:)
        delivery_partner.lead_provider_metadata.select { it.lead_provider_id == options[:lead_provider_id] }.sole
      end
    end
  end

  identifier :api_id, name: :id
  field(:type) { "delivery-partner" }

  association :attributes, blueprint: AttributesSerializer do |delivery_partner|
    delivery_partner
  end
end
