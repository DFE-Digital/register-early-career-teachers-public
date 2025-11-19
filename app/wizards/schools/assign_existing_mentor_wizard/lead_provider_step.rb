module Schools
  module AssignExistingMentorWizard
    class LeadProviderStep < Step
      include TrainingPeriodSources

      attr_accessor :lead_provider_id

      validates :lead_provider_id,
                presence: { message: 'Select a lead provider to contact your school' },
                lead_provider: { message: 'Select a lead provider to contact your school' }

      def self.permitted_params = %i[lead_provider_id]

      def previous_step = :review_mentor_eligibility

      def next_step = :confirmation

    private

      def persist
        store.lead_provider_id = lead_provider_id

        AssignMentor.new(
          ect: wizard.context.ect_at_school_period,
          mentor: wizard.context.mentor_at_school_period,
          author: wizard.author
        ).assign!

        create_mentor_training_period!
      end

      def create_mentor_training_period!
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
        @lead_provider ||= LeadProvider.find(lead_provider_id)
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
