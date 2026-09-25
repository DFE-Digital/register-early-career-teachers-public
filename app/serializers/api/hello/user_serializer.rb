class API::Hello::UserSerializer < Blueprinter::Base
  include SelfDocumentable

  schema description: "Test API for APIs restricted by the OAuth access token."

  schema_field :user_name, name: :name, type: :string, description: "The appropriate body name.", example: "Golden Leaf Teaching School Hub"
end
