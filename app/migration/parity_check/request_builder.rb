module ParityCheck
  class RequestBuilder
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ParityCheck::Configuration

    class UnrecognizedPathIdError < RuntimeError; end
    class IDOptionMissingError < RuntimeError; end

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

  private

    def formatted_path
      return path unless path.include?(ID_PLACEHOLDER)

      path.sub(ID_PLACEHOLDER, path_id)
    end

    def path_id
      id_method = options[:id]

      raise IDOptionMissingError, "Path contains ID, but options[:id] is missing" unless id_method
      raise UnrecognizedPathIdError, "Method missing for path ID: #{id_method}" unless respond_to?(id_method, true)

      send(options[:id])
    end

    def token_provider
      @token_provider ||= TokenProvider.new
    end

    def statement_id
      Statement
        .joins(:active_lead_provider)
        .where(active_lead_provider: lead_provider.active_lead_providers)
        .order("RANDOM()")
        .pick(:api_id)
    end
  end
end
