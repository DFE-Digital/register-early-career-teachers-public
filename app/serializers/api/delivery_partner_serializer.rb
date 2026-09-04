class API::DeliveryPartnerSerializer < BaseSerializer
  class AttributesSerializer < BaseSerializer
    exclude :id

    schema_field :name,
                 type: :string,
                 description: "The name of the delivery partner you are working with.",
                 example: "Awesome Delivery Partner Ltd"

    schema_field :created_at,
                 type: :datetime,
                 description: "The date and time the delivery partner was created.",
                 example: "2021-05-31T02:22:32.000Z"

    schema_field :api_updated_at,
                 name: :updated_at,
                 type: :datetime,
                 description: "The date and time the delivery partner was last updated.",
                 example: "2021-05-31T02:22:32.000Z"

    schema_field :cohort,
                 type: [:string],
                 description: "The cohorts for which you may report school partnerships with this delivery partner.",
                 example: %w[2021 2022] do |delivery_partner, options|
      delivery_partner
        .framework_agreements
        .select { it.lead_provider_id == options[:lead_provider_id] }
        .map { it.contract_period_year.to_s }
    end
  end

  def self.dependencies
    %i[framework_agreements]
  end

  schema description: "A delivery partner."

  schema_identifier :api_id,
                    name: :id,
                    **OpenAPI::Schemas::ID_ATTRIBUTE

  schema_field :type,
               type: :string,
               description: "The data type.",
               enum: %w[delivery-partner],
               example: "delivery-partner" do
    "delivery-partner"
  end

  schema_association :attributes,
                     blueprint: AttributesSerializer do |delivery_partner|
    delivery_partner
  end
end
