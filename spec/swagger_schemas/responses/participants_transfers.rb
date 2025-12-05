PARTICIPANTS_TRANSFERS_RESPONSE = {
  description: "A list of transfers",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      type: :array,
      items: { "$ref": "#/components/schemas/ParticipantTransfer" }
    },
  },
}.freeze
