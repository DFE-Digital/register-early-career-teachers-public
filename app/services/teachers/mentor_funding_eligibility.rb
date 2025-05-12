module Teachers
  class MentorFundingEligibility
    attr_reader :teacher

    def initialize(trn:)
      @teacher = Teacher.find_by(trn:)
    end

    def eligible?
      return true if teacher.nil?

      teacher.mentor_became_ineligible_for_funding_reason.blank?
    end
  end
end
