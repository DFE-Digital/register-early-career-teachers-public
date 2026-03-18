module Declarations
  module Actions
    class MarkDeclarationsEligible
      class MissingPaymentStatementError < StandardError; end

      attr_reader :declarations, :author

      def initialize(declarations:, author:)
        @declarations = declarations
        @author = author
      end

      def mark
        ApplicationRecord.transaction do
          declarations.each do |declaration|
            declaration.payment_statement = payment_statement(declaration:)
            declaration.mark_as_eligible!
            record_eligible_event!(declaration:)
          end
        end
      end

    private

      def payment_statement(declaration:)
        Statements::Search.new(
          lead_provider_id: declaration.lead_provider.id,
          contract_period_years: declaration.contract_period.year,
          fee_type: "output",
          deadline_date: Time.zone.today..,
          order: :deadline_date
        ).statements.first.tap do |statement|
          raise MissingPaymentStatementError, "Payment statement not found for declaration #{declaration.id}" if statement.nil?
        end
      end

      def record_eligible_event!(declaration:)
        Events::Record.record_teacher_declaration_eligible!(
          author:,
          teacher: declaration.training_period.teacher,
          training_period: declaration.training_period,
          declaration:
        )
      end
    end
  end
end
