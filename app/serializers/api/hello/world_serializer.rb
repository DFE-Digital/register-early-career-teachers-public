class API::Hello::WorldSerializer < Blueprinter::Base
  include SelfDocumentable

  schema description: "Test API for unrestricted API."

  schema_field :message, type: :string, description: "An anonymous greeting.", example: "Hello World"
end
