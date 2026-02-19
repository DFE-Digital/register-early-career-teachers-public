module Migration
  class StatementLineItem < Migration::Base
    self.inheritance_column = nil

    belongs_to :statement
    belongs_to :participant_declaration

    def refundable? = ParticipantDeclaration::REFUNDABLE_STATES.include?(state)
    def billable? = ParticipantDeclaration::BILLABLE_STATES.include?(state)
  end
end
