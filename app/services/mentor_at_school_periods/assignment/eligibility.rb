module MentorAtSchoolPeriods
  module Assignment
    class Eligibility
      class << self
        def for_first_provider_led_training?(ect_at_school_period:, mentor_at_school_period:)
          return false unless mentor_at_school_period && ect_at_school_period
          return false unless ect_at_school_period.provider_led_training_programme?
          return false unless teacher_eligible_for_mentor_funding?(mentor_at_school_period.teacher)

          mentor_at_school_period.teacher.mentor_training_periods.none?
        end

      private

        def teacher_eligible_for_mentor_funding?(teacher)
          Teachers::MentorFundingEligibility.new(trn: teacher.trn).eligible?
        end
      end
    end
  end
end
