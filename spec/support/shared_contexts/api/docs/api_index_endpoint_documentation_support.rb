RSpec.shared_context "an API index endpoint documentation", :exceptions_app do |url, tag, resource_description, response_schema_ref, filter_schema_ref, default_sortable, sorting_schema_ref = nil|
  path url do
    get "Retrieve multiple #{resource_description}" do
      tags tag
      consumes "application/json"
      produces "application/json"
      security [api_key: []]

      if url.match?(/schools/)
        parameter name: "filter[cohort]",
                  example: "2024",
                  in: :query,
                  style: "deepObject",
                  required: true
      end

      if filter_schema_ref
        parameter name: :filter,
                  in: :query,
                  required: false,
                  schema: {
                    "$ref": filter_schema_ref,
                  },
                  style: "deepObject"
      end

      parameter name: :page,
                in: :query,
                required: false,
                schema: {
                  "$ref": "#/components/schemas/PaginationFilter",
                },
                style: "deepObject"

      if default_sortable
        parameter name: :sort,
                  in: :query,
                  required: false,
                  schema: {
                    "$ref": "#/components/schemas/SortingOptions",
                  }
      end

      if sorting_schema_ref
        parameter name: :sort,
                  in: :query,
                  required: false,
                  schema: {
                    "$ref": sorting_schema_ref,
                  }
      end

      response "200", "A list of #{resource_description}" do
        schema({ "$ref": response_schema_ref })

        run_test!
      end

      response "401", "Unauthorized" do
        let(:token) { "invalid" }

        schema({ "$ref": "#/components/schemas/UnauthorisedResponse" })

        run_test!
      end
    end
  end
end
