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

        # TODO: Update the LP if there is a confirmed partnership, if not add an EOI
      end
    end
  end
end
