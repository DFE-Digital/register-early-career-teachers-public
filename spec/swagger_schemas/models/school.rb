SCHOOL = {
  description: "The data attributes associated with an ECF school",
  type: :object,
  required: %i[id type attributes],
  properties: {
    id: {
      "$ref": "#/components/schemas/IDAttribute",
    },
    type: {
      description: "The data type.",
      type: :string,
      example: "school",
      enum: %w[
        school
      ],
    },
    attributes: {
      properties: {
        name: {
          description: "The name of the school",
          type: :string,
          nullable: false,
          example: "School Example",
        },
        urn: {
          description: "The Unique Reference Number (URN) of the school",
          type: :string,
          nullable: false,
          example: "123456",
        },
        cohort: {
          description: "Indicates which call-off contract funds this participant's training. 2021 indicates a participant that has started, or will start, their training in the 2021/22 academic year.",
          type: :string,
          nullable: false,
          example: "2021",
        },
        in_partnership: {
          description: "Whether or not the school already has an active partnership, if it is doing a funded induction programme",
          type: :boolean,
          nullable: false,
          example: false,
        },
        induction_programme_choice: {
          description: "The induction programme the school offers",
          type: :string,
          nullable: false,
          example: "not_yet_known",
          enum: %w[
            school_led
            provider_led
            not_yet_known
          ],
        },
        expression_of_interest: {
          description: "Whether or not an ECF participant linked to the school has expressed interest in doing a funded induction programme",
          type: :boolean,
          nullable: false,
          example: false,
        },
        created_at: {
          description: "The date and time the school was created",
          type: :string,
          format: :"date-time",
          example: "2021-05-31T02:22:32.000Z",
        },
        updated_at: {
          description: "The last time a change was made to this school record by the DfE",
          type: :string,
          format: :"date-time",
          example: "2021-05-31T02:22:32.000Z",
        },
      },
    },
  },
}.freeze
