MENTORING_MENTORS_RESPONSE = {
  description: "A list of mentoring mentors.",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      type: :array,
      items: { "$ref": "#/components/schemas/MentoringMentor" },
    },
  },
}.freeze
