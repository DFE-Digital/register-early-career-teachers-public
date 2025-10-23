module Schools
  module ECTs
    module ChangeMentorWizard
      class EditStep < Step
        attribute :mentor_at_school_period_id, :string

        validates :mentor_at_school_period_id,
                  inclusion: {
                    in: ->(step) do
                      step.mentors_for_select.map { it.id.to_s }
                    end,
                    message: "Select a mentor from the list provided"
                  },
                  allow_blank: false

        def self.permitted_params = [:mentor_at_school_period_id]

        def next_step
          if mentor_eligible_for_training?
            :training
          else
            :check_answers
          end
        end

        def save!
          store.mentor_at_school_period_id = mentor_at_school_period_id if valid_step?
        end

        def mentors_for_select
          eligible_mentors.without(current_mentor_at_school_period)
        end

      private

        def pre_populate_attributes
          self.mentor_at_school_period_id = store.mentor_at_school_period_id
        end

        def mentor_eligible_for_training?
          ::MentorAtSchoolPeriods::Eligibility.for_first_provider_led_training?(
            ect_at_school_period:,
            mentor_at_school_period: selected_mentor_at_school_period
          )
        end

        def current_mentor_at_school_period
          ect_at_school_period.current_or_next_mentorship_period.mentor
        end

        def selected_mentor_at_school_period
          ect_at_school_period
            .school
            .mentor_at_school_periods
            .find(store.mentor_at_school_period_id)
        end

        def eligible_mentors
          @eligible_mentors ||= Schools::EligibleMentors
            .new(ect_at_school_period.school)
            .for_ect(ect_at_school_period)
            .includes(:teacher)
        end
      end
    end
  end
end
