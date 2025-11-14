UNFUNDED_MENTORS_RESPONSE = {
  description: "A list of unfunded mentors.",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      type: :array,
      items: { "$ref": "#/components/schemas/UnfundedMentor" },
    },
  },
}.freeze
