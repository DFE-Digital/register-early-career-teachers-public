module OpenAPI
  class SchemaResolver
    def self.resolve(schema)
      OpenAPI::Normalizer.normalize(
        new(schema).resolve
      )
    end

    def initialize(schema)
      @schema = schema
    end

    def resolve
      resolve_value(schema)
    end

  private

    attr_reader :schema

    def resolve_value(value)
      case value
      when Hash
        resolve_hash(value)
      when Array
        value.map { |item| resolve_value(item) }
      else
        value
      end
    end

    def resolve_hash(hash)
      if (reference = hash[:ref] || hash[:"$ref"] || hash["$ref"])
        resolve_reference(reference)
      else
        hash.transform_values { |value| resolve_value(value) }
      end
    end

    def resolve_reference(reference)
      name = reference.delete_prefix("#/components/schemas/")

      resolve_value(Registry.schemas.fetch(name))
    end
  end
end
