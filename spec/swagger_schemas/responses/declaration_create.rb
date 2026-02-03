DECLARATION_CREATE_RESPONSE = {
  description: "A participant declaration.",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      "$ref": "#/components/schemas/DeclarationCreate",
    },
  },
}.freeze
