PARTICIPANT_RESPONSE = {
  description: "A participant.",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      "$ref": "#/components/schemas/Participant",
    },
  },
}.freeze
