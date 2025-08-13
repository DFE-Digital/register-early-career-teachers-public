PARTNERSHIPS_RESPONSE = {
  description: "A list of partnerships.",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      type: :array,
      items: { "$ref": "#/components/schemas/Partnership" },
    },
  },
}.freeze
