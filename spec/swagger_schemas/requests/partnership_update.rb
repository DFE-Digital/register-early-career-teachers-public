PARTNERSHIP_UPDATE_REQUEST = {
  description: "A partnership update request",
  type: :object,
  required: %w[data],
  properties: {
    data: {
      description: "A partnership update",
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
          description: "A partnership update request attributes",
          type: :object,
          required: %i[delivery_partner_id],
          properties: {
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
