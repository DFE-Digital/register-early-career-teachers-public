module ParityCheck
  class DynamicRequestContent
    class UnrecognizedIdentifierError < RuntimeError; end
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :lead_provider

    def fetch(identifier)
      raise UnrecognizedIdentifierError, "Identifier not recognized: #{identifier}" unless respond_to?(identifier, true)

      send(identifier)
    end

  private

    # Path ID methods

    def example_id
      Statement
        .joins(:active_lead_provider)
        .where(active_lead_provider: lead_provider.active_lead_providers)
        .order("RANDOM()")
        .pick(:api_id)
    end

    # Request body methods

    def example_body
      {
        data: {
          type: "statements",
          attributes: {
            content: "This is an example request body.",
          },
        },
      }
    end
  end
end
