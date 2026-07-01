MENTORING_MENTOR_RESPONSE = {
  description: "A single mentoring mentor.",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      "$ref": "#/components/schemas/MentoringMentor",
    },
  },
}.freeze
