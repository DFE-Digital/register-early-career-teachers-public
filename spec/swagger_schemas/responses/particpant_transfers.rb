PARTICIPANT_TRANSFERS_RESPONSE = {
  description: "Transfers for a given participant",
  type: :object,
  required: %i[data],
  properties: {
    data: { "$ref": "#/components/schemas/ParticipantTransfer" },
  },
}.freeze
