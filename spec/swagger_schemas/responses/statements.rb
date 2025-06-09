STATEMENTS_RESPONSE = {
  description: "A list of financial statement.",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      type: :array,
      items: { "$ref": "#/components/schemas/Statement" },
    },
  },
}.freeze
