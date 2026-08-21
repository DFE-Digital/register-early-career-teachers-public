module Statements
  class MarkAsPayableJob < RecurringJob
    def perform
      Statements::MarkAsPayable.mark_all_eligible!
    end
  end
end
