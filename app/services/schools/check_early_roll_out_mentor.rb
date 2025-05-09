module Schools
  class CheckEarlyRollOutMentor
    CUT_OFF_DATE = Date.new(2021, 4, 19).freeze
    attr_accessor :trn, :teacher

    def initialize(trn)
      @trn = trn
      @teacher = Teacher.find_by(trn:)
    end

    def early_roll_out_mentor?
      if teacher.nil?
        Rails.logger.warn("checking if non-existant teacher #{trn} is early roll out mentor")
        return false
      end

      teacher.mentor_became_ineligible_for_funding_reason == "completed_during_early_roll_out"
    end

    def to_h
      {
        mentor_became_ineligible_for_funding_reason:,
        mentor_became_ineligible_for_funding_on:
      }
    end

  private

    def mentor_became_ineligible_for_funding_reason
      'completed_during_early_roll_out' if early_roll_out_mentor?
    end

    def mentor_became_ineligible_for_funding_on
      CUT_OFF_DATE if early_roll_out_mentor?
    end
  end
end
