module Statements
  class DeclarationsSearch
    attr_reader :statement

    def initialize(statement:)
      @statement = statement
    end

    def declarations
      statement_linked_declarations
        .preload(
          :delivery_partner_when_created,
          mentorship_period: { mentor: :teacher },
          training_period: [
            :lead_provider,
            :schedule,
            { ect_at_school_period: %i[school teacher] },
            { mentor_at_school_period: %i[school teacher] }
          ]
        )
        .order(:declaration_date, :created_at, :id)
        .distinct
    end

  private

    def statement_linked_declarations
      Declaration.where(payment_statement: statement)
        .or(Declaration.where(clawback_statement: statement))
    end
  end
end
