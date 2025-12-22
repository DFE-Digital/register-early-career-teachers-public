DECLARATIONS_FILTER = {
  description: "Refine participant declarations to return.",
  type: "object",
  properties: {
    cohort: {
      description: "Return participant declarations associated to the specified cohort or cohorts. This is a comma delimited string of years.",
      type: "string",
      example: "2021,2022",
    },
    participant_id: {
      description: "Return participant declarations associated to the specified participant ID. This is a comma delimited string where multiple participant IDs can be specified.",
      type: "string",
      example: "7a8fef46-3c43-42c0-b3d5-1ba5904ba562,7e727981-db9d-40d7-9e42-27eff7d66a19",
    },
    delivery_partner_id: {
      description: "Return participant declarations associated to the specified delivery partner or delivery partners. This is a comma delimited string of delivery partner IDs.",
      type: "string",
      example: "42a9ef2f-9059-400a-92ff-4830a629d0c5,92f6e54b-57fe-4a62-89cc-e83d6b0f734b",
    },
    updated_since: {
      description: "Return only records that have been updated since this date and time (ISO 8601 date format).",
      type: "string",
      example: "2021-05-13T11:21:55Z",
    },
  },
}.freeze
