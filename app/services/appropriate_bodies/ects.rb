module AppropriateBodies
  class ECTs
    attr_reader :appropriate_body

    def initialize(appropriate_body)
      @appropriate_body = appropriate_body
    end

    def current
      latest_period_ids = InductionPeriod
        .select('DISTINCT ON (teacher_id) induction_periods.id')
        .order('teacher_id, started_on DESC')

      Teacher
        .joins(:induction_periods)
        .where(induction_periods: { id: latest_period_ids, appropriate_body: })
        .merge(InductionPeriod.ongoing.or(InductionPeriod.with_outcome))
        .distinct
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
