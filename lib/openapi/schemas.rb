module OpenAPI
  module Schemas
    ID_ATTRIBUTE = {
      description: "The unique ID of the resource.",
      type: :string,
      format: :uuid,
      example: "d0b4a32e-a272-489e-b30a-cb17131457fc"
    }.freeze

    def self.paginated(item:)
      {
        type: :object,
        required: %i[data],
        properties: {
          data: {
            type: :array,
            items: item
          },
          meta: {
            type: :object,
            properties: {
              current_page: {
                type: :integer
              },
              total_pages: {
                type: :integer
              }
            }
          }
        }
      }
    end
  end
end
