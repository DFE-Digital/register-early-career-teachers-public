MENTORING_MENTOR = {
  description: "A mentor that is mentoring",
  type: :object,
  required: %i[id type attributes],
  properties: {
    id: {
      "$ref": "#/components/schemas/IDAttribute",
    },
    type: {
      description: "The data type.",
      type: :string,
      example: "mentoring-mentor",
      enum: %w[
        mentoring-mentor
      ],
    },
    attributes: {
      properties: {
        full_name: {
          description: "The full name of this mentoring mentor",
          type: :string,
          nullable: false,
          example: "John Doe",
        },
        email: {
          description: "The email address registered for this mentoring mentor",
          type: :string,
          example: "jane.smith@example.com"
        },
        teacher_reference_number: {
          description: "The Teacher Reference Number (TRN) for this mentoring mentor",
          type: :string,
          nullable: true,
          example: "1234567",
        },
        created_at: {
          description: "The date and time the mentoring mentor was created",
          type: :string,
          format: :"date-time",
          example: "2021-05-31T02:22:32.000Z",
        },
        updated_at: {
          description: "The date and time the mentoring mentor was last updated",
          type: :string,
          format: :"date-time",
          example: "2021-05-31T02:22:32.000Z",
        },
      }
    }
  }
}.freeze
