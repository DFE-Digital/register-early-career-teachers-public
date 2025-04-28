module Schools
  class CheckEarlyRollOutMentor
    CUT_OFF_DATE = Date.new(2021, 4, 19).freeze
    attr_accessor :trn

    def initialize(trn)
      @trn = trn
    end

    def early_roll_out_mentor?
      EarlyRollOutMentor.find_by(trn:).present?
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
