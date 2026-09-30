module SelfDocumentable
  extend ActiveSupport::Concern

  included do
    class_attribute :openapi_description, instance_writer: false, default: nil
    class_attribute :openapi_fields, instance_writer: false, default: {}
  end

  class_methods do
    def schema(description:)
      self.openapi_description = description
    end

    def schema_field(name, required: true, **schema, &block)
      serialized_name = schema.delete(:name) || name

      self.openapi_fields = openapi_fields.merge(serialized_name => { required:, schema: })

      field(name, name: serialized_name, &block)
    end

    def openapi_schema
      {
        description: openapi_description,
        type: :object,
        required: openapi_fields.select { |_name, definition| definition[:required] }.keys,
        properties: openapi_fields.transform_values { it[:schema] },
      }.compact
    end

    def openapi_schema_name
      name.delete_prefix("API::").delete_suffix("Serializer").gsub("::", "")
    end

    def openapi_schema_definition
      { openapi_schema_name => openapi_schema }
    end

    def openapi_ref
      { "$ref": "#/components/schemas/#{openapi_schema_name}" }
    end
  end
end
