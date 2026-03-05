module Statements
  class DeclarationsSearch
    attr_reader :statement

    def initialize(statement:)
      @statement = statement
    end

    def declarations
      Declaration.where(id: declaration_selection.selected_declaration_ids)
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

    def declaration_selection
      @declaration_selection ||= DeclarationSelection.new(statement:)
    end
  end
end
