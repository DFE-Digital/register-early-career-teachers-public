PARTICIPANTS_RESPONSE = {
  description: "A list of participants.",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      type: :array,
      items: { "$ref": "#/components/schemas/Participant" },
    },
  },
}.freeze
