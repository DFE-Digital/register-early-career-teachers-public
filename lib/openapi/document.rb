module OpenAPI
  class Document
    VERSION = "3.0.3"

    def self.build
      OpenAPI::Normalizer.normalize(new.build)
    end

    def build
      {
        openapi: VERSION,
        info:,
        paths:,
        components:
      }
    end

  private

    def info
      {
        title: "Register early career teachers API",
        version: "v3"
      }
    end

    def paths
      OpenAPI::Registry.endpoints.each_with_object({}) do |endpoint, paths|
        paths[endpoint::PATH] ||= {}
        paths[endpoint::PATH][endpoint::METHOD] = endpoint.definition
      end
    end

    def components
      {
        schemas: Registry.schemas
      }
    end
  end
end
