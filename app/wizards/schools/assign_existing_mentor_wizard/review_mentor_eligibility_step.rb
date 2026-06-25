module Schools
  module AssignExistingMentorWizard
    class ReviewMentorEligibilityStep < Step
      include TrainingPeriodSources

      # previous step is outside wizard
      def next_step = :confirmation

    private

      def persist
        assign_mentor!
        create_mentor_training_period!
      end

      def assign_mentor!
        AssignMentor.new(
          ect: ect_at_school_period,
          mentor: mentor_at_school_period,
          author:
        ).assign!
      end

      def create_mentor_training_period!
        ActiveRecord::Base.transaction do
          training_period = TrainingPeriods::Create.provider_led(
            period: mentor_at_school_period,
            started_on: mentor_at_school_period.started_on,
            school_partnership: earliest_matching_school_partnership,
            expression_of_interest:,
            mentee: ect_at_school_period,
            author:
          ).call

          record_training_period_event!(training_period)
        end
      end

      def record_training_period_event!(training_period)
        Events::Record.record_teacher_starts_training_period_event!(
          author:,
          teacher: mentor_at_school_period.teacher,
          school: mentor_at_school_period.school,
          training_period:,
          mentor_at_school_period:,
          ect_at_school_period: nil,
          happened_at: mentor_at_school_period.started_on
        )
      end

      def ect_at_school_period = wizard.context.ect_at_school_period
      def mentor_at_school_period = wizard.context.mentor_at_school_period
      def author = wizard.author

      # TrainingPeriodSources definitions
      def lead_provider
        @lead_provider ||= lead_provider_for_current_ect_training
      end

      def school = mentor_at_school_period.school

      def lead_provider_for_current_ect_training
        ECTAtSchoolPeriods::CurrentTraining
          .new(ect_at_school_period)
          .lead_provider_via_school_partnership_or_eoi
      end
    end
  end
end
