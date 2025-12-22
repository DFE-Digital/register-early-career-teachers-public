DECLARATIONS_RESPONSE = {
  description: "A list of participant declarations.",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      type: :array,
      items: { "$ref": "#/components/schemas/Declaration" },
    },
  },
}.freeze
