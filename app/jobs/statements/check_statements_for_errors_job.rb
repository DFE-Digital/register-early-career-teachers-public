module Statements
  class CheckStatementsForErrorsJob < RecurringJob
    def perform
      Statements::MarkAsPayable.check_open_statements_for_errors
      Statements::AuthorisePayment.check_payable_statements_for_errors
    end
  end
end
