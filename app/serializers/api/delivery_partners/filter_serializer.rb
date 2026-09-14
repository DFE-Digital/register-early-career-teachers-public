class API::DeliveryPartners::FilterSerializer < Blueprinter::Base
  include SelfDocumentable

  schema description: "Filter parameters for delivery partners API endpoint."

  schema_field :cohort,
               type: :integer,
               description: "The cohort year to filter delivery partners by.",
               example: 2022
end
