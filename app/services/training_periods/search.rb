module TrainingPeriods
  class Search
    attr_reader :scope

    def initialize(order: :created_at)
      @scope = TrainingPeriod.all.order(*Array(order))
    end

    def training_periods(ect_id: nil)
      filter_by_ect_id(ect_id) if ect_id

      scope
    end

  private

    def filter_by_ect_id(ect_id)
      @scope = scope.where(ect_at_school_period_id: ect_id)
    end
  end
end
