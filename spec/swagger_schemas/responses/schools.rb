SCHOOLS_RESPONSE = {
  description: "A list of schools for the given cohort.",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      type: :array,
      items: { "$ref": "#/components/schemas/School" },
    },
  },
}.freeze
