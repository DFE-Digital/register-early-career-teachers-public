UNFUNDED_MENTOR_RESPONSE = {
  description: "A single unfunded mentor.",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      "$ref": "#/components/schemas/UnfundedMentor",
    },
  },
}.freeze
