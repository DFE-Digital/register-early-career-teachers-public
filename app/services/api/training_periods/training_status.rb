module API::TrainingPeriods
  class TrainingStatus
    attr_reader :training_period

    def initialize(training_period:)
      @training_period = training_period
    end

    def status
      return :active unless training_period.withdrawn_at || training_period.deferred_at

      {
        withdrawn: training_period.withdrawn_at,
        deferred: training_period.deferred_at
      }
      .compact
      .max_by(&:last)
      .first
    end

    def active?
      status == :active
    end

    def deferred?
      status == :deferred
    end

    def withdrawn?
      status == :withdrawn
    end
  end
end
