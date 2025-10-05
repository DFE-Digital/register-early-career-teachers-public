module Schools
  module ECTs
    module ChangeMentorWizard
      class TrainingStep < Step
        attribute :accepting_current_lead_provider, :boolean

        def self.permitted_params = [:accepting_current_lead_provider]

        def previous_step = :edit
        def next_step = :check_answers

        def new_mentor = selected_mentor_at_school_period.teacher

        def save!
          store.accepting_current_lead_provider = accepting_current_lead_provider
        end
      end
    end
  end
end
