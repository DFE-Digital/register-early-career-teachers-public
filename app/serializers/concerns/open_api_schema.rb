module OpenAPISchema
  extend ActiveSupport::Concern

  included do
    class_attribute :openapi_description,
                    instance_writer: false,
                    default: nil

    class_attribute :openapi_fields,
                    instance_writer: false,
                    default: {}
  end

  class_methods do
    def schema(description: nil)
      self.openapi_description = description
    end

    def schema_field(name, required: true, **schema, &block)
      serialized_name = schema.delete(:name) || name

      register_schema_field(
        serialized_name,
        required:,
        schema:
      )

      field(name, name: serialized_name, &block)
    end

    def schema_identifier(name, required: true, **schema)
      serialized_name = schema.delete(:name) || name

      register_schema_field(
        serialized_name,
        required:,
        schema:
      )

      identifier(name, name: serialized_name)
    end

    def schema_object(name, required: true, **schema, &block)
      blueprint = Class.new(BaseSerializer) do
        exclude :id
      end

      blueprint.class_eval(&block)

      register_schema_field(
        name,
        required:,
        schema: blueprint.openapi_schema.merge(schema)
      )

      association(name, blueprint:) do |record|
        record
      end
    end

    def schema_association(name, blueprint:, required: true, **schema, &block)
      register_schema_field(
        name,
        required:,
        schema: blueprint.openapi_schema.merge(schema)
      )

      association(name, blueprint:, &block)
    end

    def openapi_schema
      {
        description: openapi_description,
        type: :object,
        required: required_schema_fields,
        properties: schema_properties,
      }.compact
    end

    def openapi_schema_name
      name
        .delete_prefix("API::")
        .delete_suffix("Serializer")
    end

    def openapi_ref
      {
        "$ref": "#/components/schemas/#{openapi_schema_name}"
      }
    end

  private

    def register_schema_field(name, required:, schema:)
      self.openapi_fields = openapi_fields.merge(
        name => {
          required:,
          schema:,
        }
      )
    end

    def required_schema_fields
      openapi_fields
        .select { |_name, definition| definition[:required] }
        .keys
    end

    def schema_properties
      openapi_fields.transform_values do |definition|
        definition.fetch(:schema)
      end
    end
  end
end
