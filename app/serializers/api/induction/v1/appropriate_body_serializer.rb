class API::Induction::V1::AppropriateBodySerializer < Blueprinter::Base
  include SelfDocumentable

  schema description: "An appropriate body."

  schema_field :external_id, name: :id, type: :string, description: "The appropriate body UUID.", example: "123e4567-e89b-12d3-a456-426614174000"
  schema_field :name, type: :string, description: "The appropriate body name.", example: "Golden Leaf Teaching School Hub"
end
