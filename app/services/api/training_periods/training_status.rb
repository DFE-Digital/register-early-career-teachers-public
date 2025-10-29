module API::TrainingPeriods
  class TrainingStatus
    attr_reader :training_period

    def initialize(training_period:)
      @training_period = training_period
    end

    def status
      if training_period.withdrawn_at
        :withdrawn
      elsif training_period.deferred_at
        :deferred
      else
        :active
      end
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
