PARTNERSHIP_RESPONSE = {
  description: "A single partnership.",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      "$ref": "#/components/schemas/Partnership",
    },
  },
}.freeze
