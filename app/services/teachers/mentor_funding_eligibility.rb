module Teachers
  class MentorFundingEligibility
    attr_reader :teacher

    def initialize(trn:)
      @teacher = Teacher.find_by(trn:)
    end

    # TODO: `mentor_became_ineligible_for_funding_on` is a date,
    # should we pass in a date to determine eligibility? (Date.today or "mentoring start date")

    def eligible?
      return true if teacher.nil?

      teacher.mentor_became_ineligible_for_funding_reason.blank?
    end
  end
end
