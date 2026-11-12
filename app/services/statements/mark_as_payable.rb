module Statements
  class StatementNotOpenError < StandardError; end

  class MarkAsPayable
    attr_reader :statement

    def self.mark_all_eligible!
      deadline_past_statements = Statements::Search.new(
        status: "open",
        deadline_date: ...Date.current,
        order: :deadline_date
      ).statements

      deadline_past_statements.find_each do |statement|
        new(statement).mark!
      end
    end

    def self.check_open_statements_for_errors
      Statement.with_status(:open).find_each do |statement|
        new(statement).report_invalid_declarations
      end
    end

    def initialize(statement)
      @statement = statement
    end

    def mark!
      raise StatementNotOpenError, "Cannot mark statement as payable: statement is #{statement.status}" unless statement.open?

      ActiveRecord::Base.transaction do
        eligible_declarations.find_each do |declaration|
          declaration.mark_as_payable!
          record_declaration_payable_event!(declaration)
        end
        statement.mark_as_payable!
        record_statement_payable_event!
      end
    end

    def report_invalid_declarations
      eligible_declarations.find_each do |declaration|
        next if declaration.valid?

        Sentry.with_scope do |scope|
          scope.set_context("errors", declaration.errors.messages) if scope
          Sentry.capture_message("[MarkAsPayable-Check] - Declaration [#{declaration.id}] invalid on statement [#{statement.id}]")
        end
      end
    end

  private

    def eligible_declarations
      statement.payment_declarations.payment_status_eligible
    end

    def record_declaration_payable_event!(declaration)
      Events::Record.record_teacher_declaration_payable!(
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
