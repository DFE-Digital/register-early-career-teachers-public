DELIVERY_PARTNER = {
  description: "A delivery partner.",
  type: :object,
  required: %i[id type attributes],
  properties: {
    id: {
      "$ref": "#/components/schemas/IDAttribute"
    },
    type: {
      description: "The data type.",
      type: :string,
      example: "delivery-partner",
      enum: %w[
        delivery-partner
      ]
    },
    attributes: {
      properties: {
        name: {
          description: "The name of the delivery partner you are working with.",
          type: :string,
          nullable: false,
          example: "Awesome Delivery Partner Ltd"
        },
        cohort: {
          description: "The cohorts for which you may report school partnerships with this delivery partner.",
          type: :array,
          nullable: false,
          example: %w[2021 2022]
        },
        created_at: {
          description: "The date and time the delivery partner was created.",
          type: :string,
          format: :"date-time",
          example: "2021-05-31T02:22:32.000Z"
        },
        updated_at: {
          description: "The date and time the delivery partner was last updated.",
          type: :string,
          format: :"date-time",
          example: "2021-05-31T02:22:32.000Z"
        }
      }
    }
  }
}.freeze
