module API
  class AnalyticsUser
    attr_reader :lead_provider

    def initialize(lead_provider)
      @lead_provider = lead_provider
    end

    delegate :name, to: :lead_provider

    def fingerprint = lead_provider.short_name
  end
end
