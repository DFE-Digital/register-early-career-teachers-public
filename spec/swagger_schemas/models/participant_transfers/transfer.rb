PARTICIPANT_TRANSFERS_TRANSFER = {
  description: "A participant transfer, transfer",
  type: :object,
  required: %i[
    training_record_id
    transfer_type
    status
    leaving
  ],
  properties: {
    training_record_id: {
      description: "The unique identifier of this participant's training record. Should the DfE dedupe a participant, this value will not change.",
      type: :string,
      format: :uuid,
      example: "42a9ef2f-9059-400a-92ff-4830a629d0c5"
    },
    transfer_type: {
      description: "The type of transfer between schools",
      type: :string,
      enum: %w[
        new_school
        new_provider
        unknown
      ],
      example: "new_provider"
    },
    status: {
      description: "The status of the transfer, if both leaving and joining SIT have completed their journeys or only one has",
      type: :string,
      enum: %w[
        incomplete
        complete
      ],
      example: "complete"
    },
    leaving: {
      type: :object,
      required: %i[
        school_urn
      ],
      properties: {
        school_urn: {
          description: "The URN of the school the participant is leaving",
          type: :string,
          example: "123456"
        },
        provider: {
          description: "The name of the provider the participant is leaving",
          type: :string,
          example: "Example Institute"
        },
        date: {
          description: "The date the participant will be leaving the school",
          type: :string,
          format: :date,
          example: "2021-05-31"
        }
      }
    },
    joining: {
      type: :object,
      required: %i[
        school_urn
      ],
      properties: {
        school_urn: {
          description: "The URN of the school the participant is joining",
          type: :string,
          example: "654321"
        },
        provider: {
          description: "The name of the provider the participant is joining",
          type: :string,
          example: "Example Institute"
        },
        date: {
          description: "The date the participant will be joining the school",
          type: :string,
          format: :date,
          example: "2021-06-01"
        }
      }
    }
  }
}.freeze
