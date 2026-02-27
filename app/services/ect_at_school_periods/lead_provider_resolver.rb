module ECTAtSchoolPeriods
  class LeadProviderResolver
    def initialize(ect_at_school_period)
      @ect_at_school_period = ect_at_school_period
    end

    def call
      current_training_lead_provider || withdrawn_or_deferred_lead_provider
    end

  private

    attr_reader :ect_at_school_period

    def current_training_lead_provider
      CurrentTraining
        .new(ect_at_school_period)
        .lead_provider_via_school_partnership_or_eoi
    rescue NoTrainingPeriodError
      nil
    end

    def withdrawn_or_deferred_lead_provider
      training_period = ect_at_school_period.latest_training_period
      return unless training_period&.provider_led_training_programme?
      return unless training_period.status.in?(%i[withdrawn deferred])

      if training_period.only_expression_of_interest?
        training_period.expression_of_interest&.lead_provider
      else
        training_period.lead_provider
      end
    end
  end
end
