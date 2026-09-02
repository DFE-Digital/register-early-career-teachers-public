module OpenAPI
  class Registry
    ENDPOINTS = [
      Endpoints::V3::DeliveryPartners::Index
    ].freeze

    SERIALIZERS = [
      API::DeliveryPartnerSerializer
    ].freeze

    def self.endpoints
      ENDPOINTS
    end

    def self.schemas
      SERIALIZERS.to_h do |serializer|
        [
          serializer.openapi_schema_name,
          serializer.openapi_schema
        ]
      end
    end
  end
end
