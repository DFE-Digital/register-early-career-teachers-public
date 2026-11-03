class Events::AppropriateBodyAPIAuthor
  attr_reader :appropriate_body_period, :oauth_client

  def initialize(appropriate_body_period:, oauth_client: nil)
    @appropriate_body_period = appropriate_body_period
    @oauth_client = oauth_client
  end

  def event_author_params
    {
      author_type: :appropriate_body_api,
      author_name: appropriate_body_period.name,
      oauth_client:,
    }.compact
  end
end
