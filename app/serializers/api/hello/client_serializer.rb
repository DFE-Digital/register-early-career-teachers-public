class API::Hello::ClientSerializer < Blueprinter::Base
  include SelfDocumentable

  schema description: "Test API for APIs restricted by the client credentials."

  schema_field :name, type: :string, description: "The API client name.", example: "Vendor Ltd"
end
