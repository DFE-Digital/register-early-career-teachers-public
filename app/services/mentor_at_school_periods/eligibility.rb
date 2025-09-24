module MentorAtSchoolPeriods
  class Eligibility
    def self.for_first_provider_led_training?(ect_at_school_period:, mentor_at_school_period:)
      return false unless mentor_at_school_period && ect_at_school_period

      ect_at_school_period.provider_led_training_programme? &&
        Teachers::MentorFundingEligibility.new(trn: mentor_at_school_period.teacher.trn).eligible? &&
        mentor_at_school_period.training_periods.ongoing.none?
    end
  end
end
