module SelfDocumentable::Serializer
  extend ActiveSupport::Concern

  include SelfDocumentable

  class_methods do
    def schema_field(field_name, name: field_name, **, &block)
      super(name, **)

      field(field_name, name:, &block)
    end

    def openapi_schema_name(...)
      super.delete_suffix("Serializer")
    end
  end
end
