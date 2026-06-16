module TrainingPeriods
  class RelatedPeriods
    attr_reader :training_period

    def initialize(training_period:)
      @training_period = training_period
    end

    def current_active_period
      related_periods.ongoing_today.first
    end

    def future_periods
      related_periods
        .started_after(Time.zone.today)
        .earliest_first
    end

  private

    def related_periods
      TrainingPeriod.where(id: related_period_ids)
    end

    def related_period_ids
      @related_period_ids ||= [training_period.id, *training_period.siblings.ids]
    end
  end
end
