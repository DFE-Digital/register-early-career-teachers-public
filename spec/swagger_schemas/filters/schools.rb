SCHOOLS_FILTER = {
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
    urn: {
      description: "Return a school with the specified Unique Reference Number (URN).",
      type: "string",
      example: "106286",
    },
    updated_since: {
      description: "Return only records that have been updated since this date and time (ISO 8601 date format)",
      type: "string",
      example: "2021-05-13T11:21:55Z",
    },
  },
}.freeze
