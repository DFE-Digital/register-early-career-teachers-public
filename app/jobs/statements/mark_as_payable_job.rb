module Statements
  class MarkAsPayableJob < ApplicationJob
    def perform
      Statements::MarkAsPayable.mark_all_eligible!
    end
  end
end
