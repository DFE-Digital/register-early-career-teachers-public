module AppropriateBodies
  module ClaimAnECT
    class RegisterECT
      include ::Teachers::Manageable

      attr_reader :appropriate_body,
                  :pending_induction_submission,
                  :author

      def initialize(appropriate_body:, pending_induction_submission:, author:)
        @appropriate_body = appropriate_body
        @pending_induction_submission = pending_induction_submission
        @author = author
      end

      # @param pending_induction_submission_params [ActionController::Parameters]
      def register(pending_induction_submission_params)
        pending_induction_submission.assign_attributes(**pending_induction_submission_params)

        induction_programme = ::PROGRAMME_MAPPER[pending_induction_submission_params[:training_programme]]
        pending_induction_submission.assign_attributes(induction_programme:) if induction_programme.present?

        ActiveRecord::Base.transaction do
          steps = [
            pending_induction_submission.save(context: :register_ect),
            update_name!,
            update_trs_induction_status!,
            update_trs_attributes!,
            create_induction_period
          ]

          steps.all? or raise ActiveRecord::Rollback
        end
      end

    private

      alias_method :trs_data, :pending_induction_submission

      # @return [Teachers::Manage]
      def manage_teacher
        @manage_teacher ||= ::Teachers::Manage.find_or_initialize_by(
          trn: pending_induction_submission.trn,
          trs_first_name: pending_induction_submission.trs_first_name,
          trs_last_name: pending_induction_submission.trs_last_name,
          event_metadata: Events::Metadata.with_author_and_appropriate_body(author:, appropriate_body:)
        )
      end

      # @return [Teacher]
      delegate :teacher, to: :manage_teacher

      # @return [Boolean]
      def update_trs_induction_status!
        manage_teacher.update_trs_induction_status!(
          trs_induction_status: "InProgress",
          trs_induction_start_date: pending_induction_submission.trs_induction_start_date,
          trs_induction_completed_date: nil
        )
      end

      # @return [Boolean]
      def create_induction_period
        InductionPeriods::CreateInductionPeriod.new(
          author:,
          teacher:,
          params: {
            appropriate_body:,
            started_on: pending_induction_submission.started_on,
            induction_programme: pending_induction_submission.induction_programme,
            training_programme: pending_induction_submission.training_programme,
          }
        ).create_induction_period!
        true
      rescue ActiveRecord::RecordInvalid
        false
      end
    end
  end
end
