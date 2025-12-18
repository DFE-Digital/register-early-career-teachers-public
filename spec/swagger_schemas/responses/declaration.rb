DECLARATION_RESPONSE = {
  description: "A participant declaration.",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      "$ref": "#/components/schemas/Declaration",
    },
  },
}.freeze
