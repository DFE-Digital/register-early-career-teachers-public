PARTICIPANT_TRANSFER = {
  description: "A participant transfer",
  type: :object,
  required: %i[id type attributes],
  properties: {
    id: {
      "$ref": "#/components/schemas/IDAttribute",
    },
    type: {
      description: "The data type.",
      type: :string,
      example: "participant-transfer",
      enum: %w[
        participant-transfer
      ],
    },
    attributes: {
      properties: {
        transfers: {
          type: :array,
          items: { "$ref": "#/components/schemas/ParticipantTransfersTransfer" }
        },
        updated_at: {
          description: "The date and time the participant transfer was last updated",
          type: :string,
          format: :"date-time",
          example: "2021-05-31T02:22:32.000Z",
        },
      }
    }
  }
}.freeze
