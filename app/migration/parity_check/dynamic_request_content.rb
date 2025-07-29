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

    def statement_id
      Statements::Query.new(lead_provider:)
        .statements
        .distinct(false)
        .reorder("RANDOM()")
        .pick(:api_id)
    end

    def school_id
      contract_period_id = ContractPeriod.order("RANDOM()").pick(:year)
      Schools::Query.new(lead_provider_id: lead_provider.id, contract_period_id:)
        .schools
        .distinct(false)
        .includes(:gias_school)
        .reorder("RANDOM()")
        .pick(gias_school: :api_id)
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
