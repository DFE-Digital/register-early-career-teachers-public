module Schools
  module AssignExistingMentorWizard
    class ReviewMentorEligibilityStep < Step
      include TrainingPeriodSources

      # previous step is outside wizard
      def next_step = :confirmation

    private

      def persist
        AssignMentor.new(
          ect: wizard.context.ect_at_school_period,
          mentor: wizard.context.mentor_at_school_period,
          author: wizard.author
        ).assign!

        create_mentor_training_period!
      end

      def create_mentor_training_period!
        return unless lead_provider

        ActiveRecord::Base.transaction do
          training_period = TrainingPeriods::Create.provider_led(
            period: mentor_at_school_period,
            started_on:,
            school_partnership: earliest_matching_school_partnership,
            expression_of_interest:,
            author: wizard.author
          ).call

          record_training_period_event!(training_period)
        end
      end

      def record_training_period_event!(training_period)
        Events::Record.record_teacher_starts_training_period_event!(
          author: wizard.author,
          teacher: mentor_at_school_period.teacher,
          school: mentor_at_school_period.school,
          training_period:,
          mentor_at_school_period:,
          ect_at_school_period: nil,
          happened_at: started_on
        )
      end

      def mentor_at_school_period
        wizard.context.mentor_at_school_period
      end

      def lead_provider
        @lead_provider ||= ect_current_lead_provider
      end

      def ect_current_lead_provider
        ECTAtSchoolPeriods::CurrentTraining.new(wizard.context.ect_at_school_period).lead_provider_via_school_partnership_or_eoi
      end

      def started_on
        mentor_at_school_period.started_on
      end

      def school
        mentor_at_school_period.school
      end
    end
  end
end
