DELIVERY_PARTNERS_FILTER = {
  description: "Filter delivery partners to return more specific results",
  type: "object",
  properties: {
    cohort: {
      description: "Return delivery partners from the specified cohort or cohorts. This is a comma delimited string of years.",
      type: "string",
      example: "2021,2022",
    },
  },
}.freeze
