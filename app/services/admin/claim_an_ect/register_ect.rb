module Admin
  module ClaimAnECT
    class RegisterECT
      attr_reader :pending_induction_submission, :induction_period, :author

      def initialize(pending_induction_submission:, author:)
        @pending_induction_submission = pending_induction_submission
        @author = author
      end

      def register(pending_induction_submission_params)
        pending_induction_submission.assign_attributes(**pending_induction_submission_params)

        ActiveRecord::Base.transaction do
          steps = [
            update_name,
            update_qts_awarded_on,
            update_itt_provider_name,
            update_trs_induction_status,
            pending_induction_submission.save(context: :register_ect),
            create_induction_period
          ]

          steps.all? or raise ActiveRecord::Rollback
        end
      end

    private

      def update_name
        manage_teacher.update_name!(
          trs_first_name: pending_induction_submission.trs_first_name,
          trs_last_name: pending_induction_submission.trs_last_name
        )
      end

      def update_qts_awarded_on
        manage_teacher.update_qts_awarded_on!(
          trs_qts_awarded_on: pending_induction_submission.trs_qts_awarded_on
        )
      end

      def update_trs_induction_status
        manage_teacher.update_trs_induction_status!(
          trs_induction_status: pending_induction_submission.trs_induction_status || 'InProgress'
        )
      end

      def update_itt_provider_name
        manage_teacher.update_itt_provider_name!(
          trs_initial_teacher_training_provider_name: pending_induction_submission.trs_initial_teacher_training_provider_name
        )
      end

      def manage_teacher
        @manage_teacher ||= ::Teachers::Manage.find_or_initialize_by(
          trn: pending_induction_submission.trn,
          trs_first_name: pending_induction_submission.trs_first_name,
          trs_last_name: pending_induction_submission.trs_last_name,
          event_metadata: { author:, appropriate_body: }
        )
      end

      def teacher
        @manage_teacher.teacher
      end

      def appropriate_body
        @appropriate_body ||= AppropriateBody.find(pending_induction_submission.appropriate_body_id) if pending_induction_submission.appropriate_body_id.present?
      end

      def create_induction_period
        return true if pending_induction_submission.finished_on.present? && pending_induction_submission.started_on.present?

        @induction_period = InductionPeriods::CreateInductionPeriod.new(
          author:,
          teacher:,
          params: {
            appropriate_body:,
            started_on: pending_induction_submission.started_on,
            finished_on: pending_induction_submission.finished_on,
            induction_programme: pending_induction_submission.induction_programme,
            number_of_terms: pending_induction_submission.number_of_terms
          }
        ).create_induction_period!
        true
      rescue ActiveRecord::RecordInvalid
        false
      end
    end
  end
end
