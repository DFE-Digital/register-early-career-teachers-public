module Schools
  class LatestChoices
    attr_reader :school, :registration_period

    def initialize(school:, registration_period:)
      @school = school
      @registration_period = registration_period
    end

    delegate :last_chosen_appropriate_body, to: :school
    delegate :last_chosen_lead_provider, to: :school

    def appropriate_body = last_chosen_appropriate_body

    def lead_provider
      last_chosen_lead_provider if active?(last_chosen_lead_provider)
    end

  private

    def active?(lead_provider)
      return false if lead_provider.blank?

      LeadProviders::Active.new(lead_provider).active_in_registration_period?(registration_period)
    end
  end
end
