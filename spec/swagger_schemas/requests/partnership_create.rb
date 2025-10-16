PARTNERSHIP_CREATE_REQUEST = {
  description: "A partnership request",
  type: :object,
  required: %w[data],
  properties: {
    data: {
      description: "A partnership",
      type: :object,
      required: %w[type attributes],
      properties: {
        type: {
          type: :string,
          required: true,
          enum: %w[
            partnership
          ],
          example: "partnership"
        },
        attributes: {
          description: "A partnership request attributes",
          type: :object,
          required: %i[cohort delivery_partner_id school_id],
          properties: {
            cohort: {
              description: "The cohort for which you are reporting the partnership",
              required: true,
              nullable: false,
              type: :string,
              example: "2022"
            },
            school_id: {
              description: "The Unique ID of the school you are partnering with",
              required: true,
              nullable: false,
              type: :string,
              example: "24b61d1c-ad95-4000-aee0-afbdd542294a"
            },
            delivery_partner_id: {
              description: "The unique ID of the delivery partner you will work with for this school partnership",
              required: true,
              nullable: false,
              type: :string,
              example: "db2fbf67-b7b7-454f-a1b7-0020411e2314"
            }
          }
        }
      }
    }
  }
}.freeze
