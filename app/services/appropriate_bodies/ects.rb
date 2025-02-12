module AppropriateBodies
  class ECTs
    attr_reader :appropriate_body

    def initialize(appropriate_body)
      @appropriate_body = appropriate_body
    end

    def current
      all.merge(InductionPeriod.ongoing)
    end

    def former
      all.merge(InductionPeriod.finished)
    end

  private

    def all
      Teacher
        .joins(:induction_periods)
        .merge(InductionPeriod.for_appropriate_body(appropriate_body))
    end
  end
end
