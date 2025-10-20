DELIVERY_PARTNER_RESPONSE = {
  description: "A delivery partner.",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      "$ref": "#/components/schemas/DeliveryPartner"
    }
  }
}.freeze
