UNFUNDED_MENTOR = {
  description: "An unfunded mentor",
  type: :object,
  required: %i[id type attributes],
  properties: {
    id: {
      "$ref": "#/components/schemas/IDAttribute",
    },
    type: {
      description: "The data type.",
      type: :string,
      example: "unfunded-mentor",
      enum: %w[
        unfunded-mentor
      ],
    },
    attributes: {
      properties: {
        full_name: {
          description: "The full name of this unfunded mentor",
          type: :string,
          nullable: false,
          example: "John Doe",
        },
        email: {
          description: "The email address registered for this unfunded mentor",
          type: :string,
          example: "jane.smith@example.com"
        },
        teacher_reference_number: {
          description: "The Teacher Reference Number (TRN) for this unfunded mentor",
          type: :string,
          nullable: true,
          example: "1234567",
        },
        created_at: {
          description: "The date and time the unfunded mentor was created",
          type: :string,
          format: :"date-time",
          example: "2021-05-31T02:22:32.000Z",
        },
        updated_at: {
          description: "The date and time the unfunded mentor was last updated",
          type: :string,
          format: :"date-time",
          example: "2021-05-31T02:22:32.000Z",
        },
      }
    }
  }
}.freeze
