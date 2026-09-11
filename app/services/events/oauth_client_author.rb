class Events::OAuthClientAuthor
  attr_reader :client

  def initialize(client:)
    @client = client
  end

  def event_author_params
    {
      author_type: :oauth_client,
      author_name: client.name,
    }
  end
end
