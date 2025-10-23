module Schools
  module ECTs
    module ChangeMentorWizard
      class ReviewMentorEligibilityStep < Step
        attribute :accepting_current_lead_provider, :boolean

        def self.permitted_params = [:accepting_current_lead_provider]

        def previous_step = :edit
        def next_step = :check_answers

        def current_lead_provider_name = lead_provider_for_ect_at_school_period&.name
        def new_mentor_name = name_for(selected_mentor_at_school_period.teacher)

        def save!
          store.accepting_current_lead_provider = accepting_current_lead_provider
        end

      private

        def selected_mentor_at_school_period
          ect_at_school_period
            .school
            .mentor_at_school_periods
            .find(store.mentor_at_school_period_id)
        end

        def lead_provider_for_ect_at_school_period
          @lead_provider_for_ect_at_school_period ||= ECTAtSchoolPeriods::CurrentTraining
            .new(ect_at_school_period)
            .lead_provider_via_school_partnership_or_eoi
        end
      end
    end
  end
end
