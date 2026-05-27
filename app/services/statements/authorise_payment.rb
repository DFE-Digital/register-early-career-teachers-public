module Statements
  class AuthorisePayment
    class NotAuthorisable < StandardError; end

    attr_reader :statement, :author

    def initialize(statement:, author:)
      @statement = statement
      @author = author
    end

    def authorise!
      raise NotAuthorisable unless statement.can_authorise_payment?

      ActiveRecord::Base.transaction do
        settle_declarations!
        refund_declarations!
        settle_statement!
      end
    end

  private

    def settle_statement!
      statement.mark_as_paid!
      statement.update!(marked_as_paid_at: Time.zone.now)
      record_statement_authorised_for_payment_event!
    end

    def settle_declarations!
      declarations_payable.find_each do |declaration|
        declaration.mark_as_paid!
        record_declaration_paid_event!(declaration)
      end
    end

    def refund_declarations!
      declarations_awaiting_clawback.find_each do |declaration|
        declaration.mark_as_clawed_back!
        record_declaration_clawed_back_event!(declaration)
      end
    end

    def declarations_payable
      statement.payment_declarations.payment_status_payable
    end

    def declarations_awaiting_clawback
      statement.payment_declarations.clawback_status_awaiting_clawback
    end

    def record_declaration_paid_event!(declaration)
      Events::Record.record_teacher_declaration_paid!(author:,
                                                      teacher: declaration.teacher,
                                                      training_period: declaration.training_period,
                                                      declaration:)
    end

    def record_declaration_clawed_back_event!(declaration)
      Events::Record.record_teacher_declaration_clawed_back!(author:,
                                                             teacher: declaration.teacher,
                                                             training_period: declaration.training_period,
                                                             declaration:)
    end

    def record_statement_authorised_for_payment_event!
      Events::Record.record_statement_authorised_for_payment_event!(author:, statement:)
    end
  end
end
