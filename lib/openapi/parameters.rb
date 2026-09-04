module OpenAPI
  module Parameters
    PAGE = {
      name: :page,
      in: :query,
      required: false,
      style: :deepObject,
      explode: true,
      schema: {
        type: :object,
        properties: {
          page: {
            type: :integer,
            minimum: 1,
            example: 1
          },
          per_page: {
            type: :integer,
            minimum: 1,
            example: 300
          }
        }
      }
    }.freeze

    COHORT_FILTER = {
      name: :"filter[cohort]",
      in: :query,
      required: false,
      description: "Comma-separated cohort years.",
      schema: {
        type: :string,
        example: "2021,2022"
      }
    }.freeze

    SORT = {
      name: :sort,
      in: :query,
      required: false,
      description: "Sort the response. Prefix with '-' for descending order.",
      schema: {
        type: :string,
        enum: %w[
          created_at
          -created_at
          updated_at
          -updated_at
          name
          -name
        ],
        example: "-created_at"
      }
    }.freeze
  end
end
