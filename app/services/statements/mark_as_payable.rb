module Statements
  class MarkAsPayable
    attr_reader :statement

    def self.mark_all!
      deadline_past_statements = Statement.where(status: :open).where(deadline_date: ..Date.current)

      deadline_past_statements.find_each do |statement|
        new(statement).mark!
      end
    end

    def initialize(statement)
      @statement = statement
    end

    def mark!
      ActiveRecord::Base.transaction do
        eligible_declarations.find_each(&:mark_as_payable!)
        statement.mark_as_payable!
      end
    end

  private

    def eligible_declarations
      statement.payment_declarations.where(payment_status: :eligible)
    end
  end
end
