module Statements
  class CheckOpenStatementsForErrorsJob < RecurringJob
    def perform
      Statements::MarkAsPayable.check_open_statements_for_errors
    end
  end
end
