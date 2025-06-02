module ECTAtSchoolPeriods
  class Training
    attr_reader :ect_at_school_period

    def initialize(ect_at_school_period)
      @ect_at_school_period = ect_at_school_period
    end

    def current_training_period
      latest_training_period if latest_training_period&.ongoing?
    end

    # current_delivery_partner
    delegate :delivery_partner, to: :current_training_period, allow_nil: true, prefix: :current

    # current_delivery_partner_name
    delegate :name, to: :current_delivery_partner, allow_nil: true, prefix: true

    # current_lead_provider
    delegate :lead_provider, to: :current_training_period, allow_nil: true, prefix: :current

    # current_lead_provider_name
    delegate :name, to: :current_lead_provider, allow_nil: true, prefix: true

    def latest_training_period
      @latest_training_period ||= ect_at_school_period.training_periods
                                                      .started_before(Date.tomorrow)
                                                      .latest_first
                                                      .first
    end

    # latest_delivery_partner
    delegate :delivery_partner, to: :latest_training_period, allow_nil: true, prefix: :latest

    # latest_delivery_partner_name
    delegate :name, to: :latest_delivery_partner, allow_nil: true, prefix: true

    # latest_lead_provider
    delegate :lead_provider, to: :latest_training_period, allow_nil: true, prefix: :latest

    # latest_lead_provider_name
    delegate :name, to: :latest_lead_provider, allow_nil: true, prefix: true
  end
end
