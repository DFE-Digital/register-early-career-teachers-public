module Statements
  class AuthorisePayment
    attr_reader :statement, :author

    def initialize(statement, author:)
      @statement = statement
      @author = author
    end

    def authorise
      return false unless statement.can_authorise_payment?

      statement.transaction do
        paid_at = Time.zone.now
        statement.marked_as_paid_at = paid_at
        statement.mark_as_paid!

        Events::Record.record_statement_authorised_for_payment_event!(
          author:,
          statement:,
          happened_at: paid_at
        )
      end

      true
    rescue StandardError => e
      Rails.logger.error("AuthorisePayment failed: #{e.class}: #{e.message}")
      false
    end
  end
end
