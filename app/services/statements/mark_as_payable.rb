module Statements
  class MarkAsPayable
    attr_reader :statement

    def self.mark_all_eligible!
      deadline_past_statements = Statement.where(status: :open).where(deadline_date: ...Date.current)

      deadline_past_statements.find_each do |statement|
        new(statement).mark!
      end
    end

    def initialize(statement)
      @statement = statement
    end

    def mark!
      ActiveRecord::Base.transaction do
        eligible_declarations.find_each do |declaration|
          declaration.mark_as_payable!
          record_declaration_payable_event!(declaration)
        end
        statement.mark_as_payable!
        record_statement_payable_event!
      end
    end

  private

    def eligible_declarations
      statement.payment_declarations.payment_status_eligible
    end

    def record_declaration_payable_event!(declaration)
      Events::Record.record_teacher_declaration_marked_payable!(
        author: Events::SystemAuthor.new,
        teacher: declaration.training_period.teacher,
        training_period: declaration.training_period,
        declaration:
      )
    end

    def record_statement_payable_event!
      Events::Record.record_statement_marked_payable!(
        author: Events::SystemAuthor.new,
        statement:
      )
    end
  end
end
