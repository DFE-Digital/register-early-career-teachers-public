module Declarations
  module Actions
    class MarkDeclarationsEligible
      attr_reader :declarations, :author

      def initialize(declarations:, author:)
        @declarations = declarations
        @author = author
      end

      def mark
        ApplicationRecord.transaction do
          declarations.payment_status_no_payment.each do |declaration|
            declaration.update!(payment_status: :eligible, payment_statement: payment_statement(declaration:))
            record_eligible_event!(declaration:, author:)
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
        ).statements.first
      end

      def record_eligible_event!(declaration:, author:)
        Events::Record.record_teacher_declaration_marked_eligible!(
          author:,
          teacher: declaration.training_period.teacher,
          training_period: declaration.training_period,
          declaration:
        )
      end
    end
  end
end
