require "api/version"

Dir[Rails.root.join("spec/swagger_schemas/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join("public/api/docs").to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v3/swagger.yaml' => {
      openapi: "3.0.1",
      info: {
        title: "Lead Provider API",
        version: "v3",
      },
      externalDocs: {
        description: "Find out more about Swagger",
        url: "https://swagger.io/",
      },
      paths: {},

      components: {
        securitySchemes: {
          api_key: {
            type: :http,
            scheme: :bearer,
            description: "Bearer token",
          },
        },

        schemas: {
          # Shared
          IDAttribute: ID_ATTRIBUTE,
          UnauthorisedResponse: UNAUTHORISED_RESPONSE,
          NotFoundResponse: NOT_FOUND_RESPONSE,
          PaginationFilter: PAGINATION_FILTER,
          SortingOptions: SORTING_OPTIONS,

          # Schools
          School: SCHOOL,
          SchoolsFilter: SCHOOLS_FILTER,
          SchoolResponse: SCHOOL_RESPONSE,
          SchoolsResponse: SCHOOLS_RESPONSE,

          # Statements
          Statement: STATEMENT,
          StatementsFilter: STATEMENTS_FILTER,
          StatementResponse: STATEMENT_RESPONSE,
          StatementsResponse: STATEMENTS_RESPONSE,
        }
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
