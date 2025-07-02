module Schools
  class LatestRegistrationChoices
    Choice = Struct.new(:lead_provider, :delivery_partner)

    attr_reader :school, :registration_period

    def initialize(school:, registration_period:)
      @school = school
      @registration_period = registration_period
    end

    delegate :last_chosen_appropriate_body, to: :school
    delegate :last_chosen_lead_provider, to: :school

    def appropriate_body = last_chosen_appropriate_body

    def lead_provider_and_delivery_partner
      if last_chosen_lead_provider.present? && matching_partnerships.any?
        Choice.new(
          lead_provider: lead_provider_delivery_partnership.active_lead_provider.lead_provider,
          delivery_partner: lead_provider_delivery_partnership.delivery_partner
        )
      end
    end

  private

    def last_chosen_lead_provider_present
      last_chosen_lead_provider.present?
    end

    def matching_partnerships
      @matching_partnerships ||= SchoolPartnerships::Query.new(
        school:,
        registration_period:,
        lead_provider: last_chosen_lead_provider
      ).school_partnerships
    end

    def first_used_partnership
      @first_used_partnership ||= matching_partnerships.earliest_first.first
    end

    def lead_provider_delivery_partnership
      @lead_provider_delivery_partnership ||= first_used_partnership.lead_provider_delivery_partnership
    end
  end
end
