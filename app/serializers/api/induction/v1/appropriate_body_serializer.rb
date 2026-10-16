class API::Induction::V1::AppropriateBodySerializer < Blueprinter::Base
  include SelfDocumentable

  schema description: "An appropriate body."

  schema_field :id, type: :integer, description: "The appropriate body identifier.", example: 123
  schema_field :name, type: :string, description: "The appropriate body name.", example: "Golden Leaf Teaching School Hub"
end
