class Events::LeadProviderAPIAuthor
  attr_reader :lead_provider

  def initialize(lead_provider:)
    @lead_provider = lead_provider
  end

  def lead_provider_api_author_params
    {
      author_type: "lead_provider_api",
      author_name: lead_provider.name,
    }
  end
end
