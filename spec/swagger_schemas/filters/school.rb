SCHOOL_FILTER = {
  description: "Filter schools to return more specific results",
  type: "object",
  required: %i[
    cohort
  ],
  properties: {
    cohort: {
      description: "Return schools within the specified cohort.",
      type: "string",
      example: "2021",
    },
  },
}.freeze
