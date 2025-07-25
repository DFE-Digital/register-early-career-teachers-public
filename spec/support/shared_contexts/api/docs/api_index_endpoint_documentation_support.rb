RSpec.shared_context "an API index endpoint documentation", :exceptions_app do |params = {}|
  path params[:url] do
    get "Retrieve multiple #{params[:resource_description]}" do
      tags params[:tag]
      consumes "application/json"
      produces "application/json"
      security [api_key: []]

      if params[:filter_schema_ref]
        parameter name: :filter,
                  in: :query,
                  required: false,
                  schema: {
                    "$ref": params[:filter_schema_ref],
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

      if params[:default_sortable]
        parameter name: :sort,
                  in: :query,
                  required: false,
                  schema: {
                    "$ref": "#/components/schemas/SortingOptions",
                  }
      end

      if params[:sorting_schema_ref]
        parameter name: :sort,
                  in: :query,
                  required: false,
                  schema: {
                    "$ref": params[:sorting_schema_ref],
                  }
      end

      response "200", "A list of #{params[:resource_description]}" do
        schema({ "$ref": params[:response_schema_ref] })

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
