class API::Induction::V1::ErrorSerializer < Blueprinter::Base
  include SelfDocumentable

  schema description: "The errors that stopped the request from succeeding."

  schema_field(
    :errors,
    type: :array,
    items: {
      type: :object,
      required: %i[title detail],
      properties: {
        title: {
          type: :string,
          example: "Conflict",
          description: "A short summary of the error, or the name of the invalid field.",
        },
        detail: {
          type: :string,
          example: "The teacher has an ongoing induction period with another appropriate body",
          description: "An explanation of the error.",
        },
      },
    },
    description: "The errors."
  )
end
