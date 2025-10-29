PARTICIPANT = {
  description: "A participant.",
  type: :object,
  required: %i[id type attributes],
  properties: {
    id: {
      "$ref": "#/components/schemas/IDAttribute",
    },
    type: {
      description: "The data type.",
      type: :string,
      example: "participant",
      enum: %w[
        participant
      ],
    },
    attributes: {
      properties: {
        full_name: {
          description: "The full name of the participant",
          type: :string,
          nullable: false,
          example: "John Doe",
        },
        teacher_reference_number: {
          description: "The Teacher Reference Number (TRN) for this participant",
          type: :string,
          nullable: true,
          example: "1234567",
        },
        ecf_enrolments: {
          type: :array,
          nullable: false,
          items: {
            "$ref": "#/components/schemas/ParticipantECFEnrolment"
          }
        },
        participant_id_changes: {
          type: :array,
          nullable: false,
          items: {
            "$ref": "#/components/schemas/ParticipantIDChange"
          }
        },
        updated_at: {
          description: "The date and time the participant was last updated.",
          type: :string,
          format: :"date-time",
          example: "2021-05-31T02:22:32.000Z",
        },
      }
    }
  }
}.freeze
