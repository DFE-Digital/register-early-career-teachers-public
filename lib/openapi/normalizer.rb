module OpenAPI
  class Normalizer
    def self.normalize(value)
      case value
      when Hash
        normalize_hash(value)
      when Array
        value.map { normalize(it) }
      when Symbol
        value.to_s
      else
        value
      end
    end

    def self.normalize_hash(value)
      value
        .then { normalize_type(it) }
        .then { normalize_ref(it) }
        .to_h do |key, child|
          [key.to_s, normalize(child)]
        end
    end

    def self.normalize_type(schema)
      case schema[:type]
      when :datetime
        schema.merge(
          type: :string,
          format: :"date-time"
        )
      when Array
        schema.merge(
          type: :array,
          items: {
            type: schema[:type].sole,
          }
        )
      else
        schema
      end
    end

    def self.normalize_ref(schema)
      return schema unless schema.key?(:ref)

      schema
        .except(:ref)
        .merge(
          "$ref": schema.fetch(:ref)
        )
    end
  end
end
