module Admin
  module ImportECT
    class CheckECT
      attr_reader :pending_induction_submission

      def initialize(pending_induction_submission:)
        @pending_induction_submission = pending_induction_submission
      end

      def import
        pending_induction_submission.tap do |submission|
          submission.confirmed = true
          submission.confirmed_at = Time.zone.now
        end

        pending_induction_submission.save(context: :check_ect)
      end
    end
  end
end
