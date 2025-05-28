module InductionPeriods
  class Search
    attr_reader :scope

    def initialize(order: :created_at)
      @scope = InductionPeriod.all.order(*Array(order))
    end

    def induction_periods(trn: nil)
      filter_by_trn(trn) if trn
      scope
    end

  private

    def filter_by_trn(trn)
      @scope = scope.joins(:teacher).where(teachers: { trn: })
    end
  end
end
