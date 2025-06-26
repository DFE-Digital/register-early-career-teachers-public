module Statements
  class AuthorisePayment
    attr_reader :statement

    def initialize(statement)
      @statement = statement
    end

    def authorise
      return false unless statement.can_authorise_payment?

      statement.marked_as_paid_at = Time.zone.now
      statement.mark_as_paid
    end
  end
end
