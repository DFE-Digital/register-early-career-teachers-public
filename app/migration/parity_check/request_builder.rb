module ParityCheck
  class RequestBuilder
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ParityCheck::Configuration

    class UnrecognizedPathIdError < RuntimeError; end
    class IDOptionMissingError < RuntimeError; end
    class UnrecognizedRequestBodyError < RuntimeError; end
    class UnrecognizedQueryError < RuntimeError; end

    ID_PLACEHOLDER = ":id".freeze

    attribute :request

    delegate :lead_provider, :endpoint, to: :request
    delegate :method, :path, :options, to: :endpoint

    def url(app:)
      parity_check_url(app:) + formatted_path
    end

    def headers
      {
        "Authorization" => "Bearer #{token_provider.token(lead_provider:)}",
        "Accept" => "application/json",
        "Content-Type" => "application/json",
      }
    end

    def body
      body_method = options[:body]

      return unless body_method

      raise UnrecognizedRequestBodyError, "Method missing for body: #{body_method}" unless respond_to?(body_method, true)

      send(body_method).to_json
    end

    def query
      query = options[:query]

      return unless query

      raise UnrecognizedQueryError, "Query must be a Hash: #{query}" unless query.is_a?(Hash)

      query
    end

  private

    def formatted_path
      return path unless path.include?(ID_PLACEHOLDER)

      path.sub(ID_PLACEHOLDER, path_id)
    end

    def path_id
      id_method = options[:id]

      raise IDOptionMissingError, "Path contains ID, but options[:id] is missing" unless id_method
      raise UnrecognizedPathIdError, "Method missing for path ID: #{id_method}" unless respond_to?(id_method, true)

      send(id_method)
    end

    def token_provider
      @token_provider ||= TokenProvider.new
    end

    # Path ID methods

    def statement_id
      Statement
        .joins(:active_lead_provider)
        .where(active_lead_provider: lead_provider.active_lead_providers)
        .order("RANDOM()")
        .pick(:api_id)
    end

    # Request body methods

    def example_statement_body
      {
        data: {
          type: "statements",
          attributes: {
            content: "This is an example request body.",
          },
        },
      }
    end
  end
end
