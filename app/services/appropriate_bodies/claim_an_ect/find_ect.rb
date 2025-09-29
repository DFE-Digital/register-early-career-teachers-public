module AppropriateBodies
  module ClaimAnECT
    class FindECT
      attr_reader :api_client, :appropriate_body, :pending_induction_submission

      def initialize(appropriate_body:, pending_induction_submission:)
        @api_client = TRS::APIClient.build
        @appropriate_body = appropriate_body
        @pending_induction_submission = pending_induction_submission
      end

      # @raise [TRS::Errors::TeacherDeactivated]
      # @raise [TRS::Errors::TeacherNotFound]
      # @raise [TRS::Errors::ProhibitedFromTeaching]
      # @raise [TRS::Errors::InductionAlreadyCompleted]
      # @raise [TRS::Errors::QTSNotAwarded]
      # @raise [AppropriateBodies::Errors::TeacherHasActiveInductionPeriodWithCurrentAB]
      #
      # @return [Boolean]
      def import_from_trs!
        # In this case, the AB attempting to claim the ECT must be able to easily reference details of the AB associated with the open induction period._

        # TODO: what do we do if we already have a matching Teacher in
        #       our database as a fully registered teacher?
        #       we probably want a guard clause here or to make the if statement
        #       below a case and add different errors to the :base
        return false unless pending_induction_submission.valid?(:find_ect)

        pending_induction_submission.assign_attributes(
          appropriate_body:,
          **trs_teacher.to_h.except(:trs_national_insurance_number)
        )

        check_if_teacher_has_ongoing_induction_period_with_appropriate_body!

        trs_teacher.check_eligibility!

        pending_induction_submission.save(context: :find_ect)
      end

    private

      # @return [TRS::Teacher]
      def trs_teacher
        @trs_teacher ||= api_client.find_teacher(
          trn: pending_induction_submission.trn,
          date_of_birth: pending_induction_submission.date_of_birth
        )
      end

      # @raise [AppropriateBodies::Errors::TeacherHasActiveInductionPeriodWithCurrentAB]
      # @return [nil]
      def check_if_teacher_has_ongoing_induction_period_with_appropriate_body!
        existing_teacher = Teacher.find_by(trn: pending_induction_submission.trn)

        return unless existing_teacher&.ongoing_induction_period

        if existing_teacher.ongoing_induction_period.appropriate_body == appropriate_body
          raise AppropriateBodies::Errors::TeacherHasActiveInductionPeriodWithCurrentAB, ::Teachers::Name.new(existing_teacher).full_name
        end
      end
    end
  end
end
