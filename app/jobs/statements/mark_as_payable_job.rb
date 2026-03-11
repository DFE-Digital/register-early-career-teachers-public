module Statements
  class MarkAsPayableJob < ApplicationJob
    def perform
      Statements::MarkAsPayable.mark_all!
    end
  end
end
