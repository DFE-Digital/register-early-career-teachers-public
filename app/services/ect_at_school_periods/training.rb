module ECTAtSchoolPeriods
  class Training
    attr_reader :ect_at_school_period, :latest_training_period

    def initialize(ect_at_school_period)
      @ect_at_school_period = ect_at_school_period

      @latest_training_period ||= ect_at_school_period.training_periods
                                                      .started_before(Date.tomorrow)
                                                      .latest_first
                                                      .first
    end

    def current_training_period
      latest_training_period if latest_training_period&.ongoing?
    end

    # Current training period

    # current_school_partnership
    delegate :school_partnership, to: :current_training_period, allow_nil: true, prefix: :current

    # current_lead_provider_delivery_partnership
    delegate :lead_provider_delivery_partnership, to: :current_school_partnership, allow_nil: true, prefix: :current, private: true

    # current_active_lead_provider
    delegate :active_lead_provider, to: :current_lead_provider_delivery_partnership, allow_nil: true, prefix: :current, private: true

    # current_lead_provider
    delegate :lead_provider, to: :current_active_lead_provider, allow_nil: true, prefix: :current

    # current_delivery_partner
    delegate :delivery_partner, to: :current_lead_provider_delivery_partnership, allow_nil: true, prefix: :current

    # current_delivery_partner_name
    delegate :name, to: :current_delivery_partner, allow_nil: true, prefix: true

    # current_lead_provider_name
    delegate :name, to: :current_lead_provider, allow_nil: true, prefix: true

    # Latest training period

    # latest_school_partnership
    delegate :school_partnership, to: :latest_training_period, allow_nil: true, prefix: :latest

    # latest_lead_provider_delivery_partnership
    delegate :lead_provider_delivery_partnership, to: :latest_school_partnership, allow_nil: true, prefix: :latest, private: true

    # latest_active_lead_provider
    delegate :active_lead_provider, to: :latest_lead_provider_delivery_partnership, allow_nil: true, prefix: :latest, private: true

    # latest_lead_provider
    delegate :lead_provider, to: :latest_active_lead_provider, allow_nil: true, prefix: :latest

    # latest_delivery_partner
    delegate :delivery_partner, to: :latest_lead_provider_delivery_partnership, allow_nil: true, prefix: :latest

    # latest_delivery_partner_name
    delegate :name, to: :latest_delivery_partner, allow_nil: true, prefix: true

    # latest_lead_provider_name
    delegate :name, to: :latest_lead_provider, allow_nil: true, prefix: true
  end
end
