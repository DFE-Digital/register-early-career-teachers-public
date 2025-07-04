module Schools
  class LatestRegistrationChoices
    Choice = Struct.new(:lead_provider, :delivery_partner)

    attr_reader :school, :contract_period

    def initialize(school:, contract_period:)
      @school = school
      @contract_period = contract_period
    end

    delegate :last_chosen_appropriate_body, to: :school
    delegate :last_chosen_lead_provider, to: :school

    def appropriate_body = last_chosen_appropriate_body

    def lead_provider_and_delivery_partner
      return nil if last_chosen_lead_provider.blank?

      if matching_partnerships.any?
        Choice.new(
          lead_provider: last_chosen_lead_provider,
          delivery_partner: lead_provider_delivery_partnership.delivery_partner
        )
      elsif LeadProviders::Active.new(last_chosen_lead_provider).active_in_contract_period?(contract_period)
        Choice.new(
          lead_provider: last_chosen_lead_provider
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
        contract_period:,
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
