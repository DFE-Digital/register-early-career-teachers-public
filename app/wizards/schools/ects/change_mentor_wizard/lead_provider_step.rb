module Schools
  module ECTs
    module ChangeMentorWizard
      class LeadProviderStep < Step
        attribute :lead_provider_id, :string

        validates :lead_provider_id,
                  presence: { message: "Select which lead provider will be training the ECT" },
                  lead_provider: { message: "Enter the name of a known lead provider" }

        def self.permitted_params = [:lead_provider_id]

        def previous_step = :training
        def next_step = :check_answers

        def new_mentor = selected_mentor_at_school_period.teacher

        def save!
          store.lead_provider_id = lead_provider_id if valid_step?
        end

      private

        def pre_populate_attributes
          self.lead_provider_id = store.lead_provider_id
        end
      end
    end
  end
end
