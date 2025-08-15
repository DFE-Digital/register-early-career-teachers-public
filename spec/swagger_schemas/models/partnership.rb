PARTNERSHIP = {
  description: "A partnership.",
  type: :object,
  required: %i[id type attributes],
  properties: {
    id: {
      "$ref": "#/components/schemas/IDAttribute",
    },
    type: {
      description: "The data type.",
      type: :string,
      example: "partnership",
      enum: %w[
        partnership
      ],
    },
    attributes: {
      properties: {
        cohort: {
          description: "The cohort for which you are reporting the partnership",
          type: "string",
          example: 2021
        },
        urn: {
          description: "The Unique Reference Number (URN) of the school you are partnered with",
          type: "string",
          example: "123456"
        },
        school_id: {
          description: "The unique ID of the school you are partnered with",
          type: "string",
          format: "uuid",
          example: "dd4a11347-7308-4879-942a-c4a70ced400v"
        },
        delivery_partner_id: {
          description: "The unique ID of the delivery partner you are working with for this partnership",
          type: "string",
          format: "uuid",
          example: "cd3a12347-7308-4879-942a-c4a70ced400a"
        },
        delivery_partner_name: {
          description: "The name of the delivery partner you are working with for this partnership",
          type: "string",
          example: "Delivery Partner Example"
        },
        induction_tutor_name: {
          description: "The name of the induction tutor at the school you are in partnership with",
          type: "string",
          nullable: true,
          example: "John Doe"
        },
        induction_tutor_email: {
          description: "The email address of the induction tutor at the school you are in partnership with",
          type: "string",
          nullable: true,
          example: "john.doe@example.com"
        },
        updated_at: {
          description: "The date the partnership was last updated",
          type: "string",
          format: "date-time",
          example: "2021-05-31T02:22:32.000Z"
        },
        created_at: {
          description: "The date the partnership was reported by you",
          type: "string",
          format: "date-time",
          example: "2021-05-31T02:22:32.000Z"
        }
      },
    },
  },
}.freeze
