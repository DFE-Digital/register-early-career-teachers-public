SCHOOL_RESPONSE = {
  description: "A single school.",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      "$ref": "#/components/schemas/School",
    },
  },
}.freeze
