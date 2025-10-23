NOT_FOUND_RESPONSE = {
  description: "The requested resource was not found.",
  type: :object,
  properties: {
    errors: {
      type: :array,
      items: {
        type: :object,
        properties: {
          title: {
            type: :string,
            example: "Resource not found",
          },
          detail: {
            type: :string,
            example: "Nothing could be found for the provided details",
          },
        },
      },
    },
  },
}.freeze
