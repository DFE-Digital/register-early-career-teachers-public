module Schools
  module AssignExistingMentorWizard
    class LeadProviderStep < Step
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
        Schools::CreateMentorTrainingPeriod.new(
          mentor_at_school_period: wizard.context.mentor_at_school_period,
          lead_provider: selected_lead_provider,
          author: wizard.author,
          started_on: wizard.context.mentor_at_school_period.started_on
        ).create!
      end

      def selected_lead_provider
        @selected_lead_provider ||= LeadProvider.find(lead_provider_id)
      end
    end
  end
end
