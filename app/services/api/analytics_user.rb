module API
  class AnalyticsUser
    attr_reader :lead_provider

    def initialize(lead_provider)
      @lead_provider = lead_provider
    end

    delegate :name, to: :lead_provider

    # NOTE: would short_name make more sense here?
    def fingerprint = lead_provider.id
  end
end
