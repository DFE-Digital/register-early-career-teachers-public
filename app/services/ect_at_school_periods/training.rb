module ECTAtSchoolPeriods
  class Training
    attr_reader :ect_at_school_period, :latest_training_period

    def initialize(ect_at_school_period)
      @ect_at_school_period = ect_at_school_period

      @latest_training_period ||= ect_at_school_period.training_periods
                                                      .eager_load(**eager_load_confirmed_partnership_tables)
                                                      .started_before(Date.tomorrow)
                                                      .latest_first
                                                      .first
    end

    def current_training_period
      latest_training_period if latest_training_period&.ongoing?
    end

    def current_lead_provider
      current_training_period
        &.school_partnership
        &.lead_provider_delivery_partnership
        &.active_lead_provider
        &.lead_provider
    end

    def current_delivery_partner
      current_training_period
        &.school_partnership
        &.lead_provider_delivery_partnership
        &.delivery_partner
    end

    # current_delivery_partner_name
    delegate :name, to: :current_delivery_partner, allow_nil: true, prefix: true

    # current_lead_provider_name
    delegate :name, to: :current_lead_provider, allow_nil: true, prefix: true

    def latest_lead_provider
      latest_training_period
        &.school_partnership
        &.lead_provider_delivery_partnership
        &.active_lead_provider
        &.lead_provider
    end

    def latest_delivery_partner
      latest_training_period
        &.school_partnership
        &.lead_provider_delivery_partnership
        &.delivery_partner
    end

    # latest_delivery_partner_name
    delegate :name, to: :latest_delivery_partner, allow_nil: true, prefix: true

    # latest_lead_provider_name
    delegate :name, to: :latest_lead_provider, allow_nil: true, prefix: true

  private

    def eager_load_confirmed_partnership_tables
      {
        school_partnership: {
          lead_provider_delivery_partnership: [
            :delivery_partner,
            { active_lead_provider: %i[lead_provider registration_period] }
          ]
        }
      }
    end
  end
end
