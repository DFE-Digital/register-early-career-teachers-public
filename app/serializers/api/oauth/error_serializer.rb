class API::OAuth::ErrorSerializer < Blueprinter::Base
  include SelfDocumentable

  schema description: "An OAuth 2.0 error."

  schema_field :error,
               type: :string,
               description: "The OAuth 2.0 error code.",
               example: "invalid_token"
end
