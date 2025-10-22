PARTICIPANTS_FILTER = {
  description: "Filter participants to return more specific results",
  type: "object",
  properties: {
    cohort: {
      description: "Return participants from the specified cohort or cohorts. This is a comma delimited string of years.",
      type: :string,
      example: "2021,2022",
    },
    updated_since: {
      description: "Return only records that have been updated since this date and time (ISO 8601 date format)",
      type: :string,
      example: "2021-05-13T11:21:55Z",
    },
    training_status: {
      description: "Return participants with the specified training status",
      type: :string,
      enum: %w[withdrawn deferred active]
    },
    from_participant_id: {
      description: "Return participants that have this from participant ID",
      type: :string,
      format: :uuid,
      example: "42a9ef2f-9059-400a-92ff-4830a629d0c5"
    }
  },
}.freeze
