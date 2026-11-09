module Statements
  class CheckForthcomingStatementsJob < RecurringJob
    def perform
      Statements::MarkAsPayable.check_forthcoming_statements!
    end
  end
end
