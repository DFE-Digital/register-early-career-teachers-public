module ECTAtSchoolPeriods
  class CurrentTraining
    attr_reader :ect_at_school_period, :current_training_period

    def initialize(ect_at_school_period)
      @ect_at_school_period = ect_at_school_period
      @current_training_period = ect_at_school_period.current_training_period
    end

    def expression_of_interest?
      school_partnership.blank? && expression_of_interest.present?
    end

    def lead_provider_via_school_partnership_or_eoi
      lead_provider || expression_of_interest_lead_provider
    end

    # school_partnership
    delegate :school_partnership, to: :current_training_period, allow_nil: true

    # lead_provider_delivery_partnership
    delegate :lead_provider_delivery_partnership, to: :school_partnership, allow_nil: true, private: true

    # active_lead_provider
    delegate :active_lead_provider, to: :lead_provider_delivery_partnership, allow_nil: true, private: true

    # expression_of_interest
    delegate :expression_of_interest, to: :current_training_period, allow_nil: true, private: true

    # expression_of_interest_lead_provider
    delegate :lead_provider, to: :expression_of_interest, allow_nil: true, prefix: :expression_of_interest, private: true

    # lead_provider
    delegate :lead_provider, to: :active_lead_provider, allow_nil: true

    # delivery_partner
    delegate :delivery_partner, to: :lead_provider_delivery_partnership, allow_nil: true

    # delivery_partner_name
    delegate :name, to: :delivery_partner, allow_nil: true, prefix: true

    # lead_provider_name
    delegate :name, to: :lead_provider, allow_nil: true, prefix: true

    # expression_of_interest_lead_provider_name
    delegate :name, to: :expression_of_interest_lead_provider, allow_nil: true, prefix: :expression_of_interest_lead_provider

    # training_programme
    delegate :training_programme, to: :current_training_period, allow_nil: true

    def provider_led?
      current_training_period&.provider_led_training_programme?
    end
  end
end
