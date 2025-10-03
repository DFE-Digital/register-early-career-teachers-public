module Statements
  class AuthorisePayment
    class NotAuthorisable < StandardError; end

    attr_reader :statement, :author

    def initialize(statement, author:)
      @statement = statement
      @author = author
    end

    def authorise!
      ActiveRecord::Base.transaction do
        raise NotAuthorisable unless statement.can_authorise_payment?

        return true if statement.marked_as_paid_at.present?

        paid_at = Time.zone.now

        statement.update!(marked_as_paid_at: paid_at)
        statement.mark_as_paid!

        Events::Record.record_statement_authorised_for_payment_event!(
          author:,
          statement:,
          happened_at: paid_at
        )

        true
      end
    end
  end
end
