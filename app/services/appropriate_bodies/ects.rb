module AppropriateBodies
  class ECTs
    attr_reader :scope, :appropriate_body

    def initialize(appropriate_body)
      @scope = Teacher.joins(:induction_periods)
                      .merge(InductionPeriod.for_appropriate_body(appropriate_body))

      @appropriate_body = appropriate_body
    end

    def with_status(status)
      case status
      when 'closed'
        completed_while_at_appropriate_body
      when 'open'
        current
      else
        current_or_completed_while_at_appropriate_body
      end
    end

    def current
      @scope.merge(InductionPeriod.ongoing)
    end

    def former
      @scope.merge(InductionPeriod.finished.without_outcome)
    end

    def all
      @scope
    end

    def completed_while_at_appropriate_body
      @scope.merge(InductionPeriod.with_outcome)
    end

    def current_or_completed_while_at_appropriate_body
      current.or(completed_while_at_appropriate_body)
    end
  end
end
