STATEMENT = {
  description: "A financial statement.",
  type: :object,
  required: %i[id type attributes],
  properties: {
    id: {
      "$ref": "#/components/schemas/IDAttribute",
    },
    type: {
      description: "The data type.",
      type: :string,
      example: "statement",
      enum: %w[
        statement
      ],
    },
    attributes: {
      properties: {
        month: {
          description: "The calendar month which corresponds to the financial statement.",
          type: :string,
          nullable: false,
          example: "May",
        },
        year: {
          description: "The calendar year which corresponds to the financial statement.",
          type: :string,
          nullable: false,
          example: "2022",
        },
        cohort: {
          description: "The cohort, for example, 2021 or 2025, which the statement funds.",
          type: :string,
          nullable: false,
          example: "2021",
        },
        cut_off_date: {
          description: "The milestone cut off or review point for the statement.",
          type: :string,
          nullable: false,
          example: "2022-04-30",
        },
        payment_date: {
          description: "The date we expect to pay you for any declarations attached to the statement, which are eligible for payment.",
          type: :string,
          nullable: false,
          example: "2022-05-25",
        },
        paid: {
          description: "Indicates whether the DfE has paid providers for any declarations attached to the statement.",
          type: :boolean,
          nullable: false,
          example: true,
        },
        created_at: {
          description: "The date the statement was created.",
          type: :string,
          format: :"date-time",
          example: "2021-05-31T02:22:32.000Z",
        },
        updated_at: {
          description: "The date the statement was last updated.",
          type: :string,
          format: :"date-time",
          example: "2021-05-31T02:22:32.000Z",
        },
      },
    },
  },
}.freeze
