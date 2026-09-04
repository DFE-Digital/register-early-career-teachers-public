module OpenAPI
  module Endpoints
    module V3
      module DeliveryPartners
        class Index
          PATH = "/api/v3/delivery-partners"
          METHOD = :get

          def self.definition
            {
              operationId: "getDeliveryPartners",
              summary: "Get delivery partners",
              tags: ["Delivery partners"],
              parameters:,
              responses:
            }
          end

          def self.parameters
            [
              OpenAPI::Parameters::PAGE,
              OpenAPI::Parameters::SORT,
              OpenAPI::Parameters::COHORT_FILTER,
            ]
          end

          def self.responses
            {
              200 => {
                description: "A list of delivery partners.",
                content: {
                  "application/json": {
                    schema: OpenAPI::Schemas.paginated(
                      item: API::DeliveryPartnerSerializer.openapi_ref
                    ),
                    example: OpenAPI::Examples.fetch(
                      endpoint: self,
                      status: 200
                    )
                  }.compact
                }
              }
            }
          end

          def self.response_schema(status)
            responses
              .fetch(status)
              .fetch(:content)
              .fetch(:"application/json")
              .fetch(:schema)
          end
        end
      end
    end
  end
end
