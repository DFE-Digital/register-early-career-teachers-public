module Teachers
  class MentorFundingEligibility
    attr_reader :teacher

    def initialize(trn:)
      @teacher = Teacher.find_by(trn:)
    end

    def eligible?
      case
      when teacher.nil?
        # we don't know the teacher isn't eligible, so
        # assume they are
        true
      when marked_as_ineligible?
        false
      else
        true
      end
    end

  private

    def marked_as_ineligible?
      teacher.mentor_became_ineligible_for_funding_on.present? && teacher.mentor_became_ineligible_for_funding_reason.present?
    end
  end
end
