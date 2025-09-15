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

    def linkable_to_school_partnership(school:, lead_provider:, contract_period:)
      @scope = scope
        .where(school_partnership_id: nil)
        .at_school(school.id)
        .joins(:expression_of_interest)
        .where(active_lead_providers: {
          lead_provider_id: lead_provider.id,
          contract_period_year: contract_period.year
        }).distinct
    end

  private

    def filter_by_ect_id(ect_id)
      @scope = scope.where(ect_at_school_period_id: ect_id)
    end
  end
end
