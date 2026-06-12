module Schools
  module ECTs
    module ChangeMentorWizard
      class EditStep < Step
        attribute :mentor_at_school_period_id, :string

        validate :mentor_is_selectable

        def self.permitted_params = [:mentor_at_school_period_id]

        def next_step
          if mentor_eligible_for_training?
            :review_mentor_eligibility
          else
            :check_answers
          end
        end

        def save!
          store.mentor_at_school_period_id = mentor_at_school_period_id if valid_step?
        end

        def mentors_for_select
          eligible_mentors.excluding(current_mentor_at_school_period)
        end

      private

        def mentor_is_selectable
          unless mentor_at_school_period_id.present? && mentors_for_select.exists?(id: mentor_at_school_period_id)
            errors.add(:mentor_at_school_period_id, "Select a mentor from the list provided")
          end
        end

        def pre_populate_attributes
          self.mentor_at_school_period_id = @wizard.new_mentor_requested ? 0 : store.mentor_at_school_period_id
        end

        def mentor_eligible_for_training?
          return false unless selected_mentor_at_school_period

          ::MentorAtSchoolPeriods::Assignment::Eligibility.for_first_provider_led_training?(
            ect_at_school_period:,
            mentor_at_school_period: selected_mentor_at_school_period
          )
        end

        def current_mentor_at_school_period
          ect_at_school_period.current_or_next_mentorship_period&.mentor
        end

        def selected_mentor_at_school_period
          @selected_mentor_at_school_period ||= mentors_for_select
            .find_by(id: store.mentor_at_school_period_id)
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
