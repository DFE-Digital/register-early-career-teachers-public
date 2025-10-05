module Schools
  module ECTs
    module MentorAtSchoolPeriods
      module Assignable
        extend ActiveSupport::Concern

        def mentors_for_select
          eligible_mentors.without(current_mentor_at_school_period)
        end

      private

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

        def mentor_eligible_for_training?
          ::MentorAtSchoolPeriods::Eligibility.for_first_provider_led_training?(
            ect_at_school_period:,
            mentor_at_school_period: selected_mentor_at_school_period
          )
        end
      end
    end
  end
end
