module ParityCheck
  class RequestBuilder
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :endpoint

    delegate :lead_provider, :method, :path, :options, to: :endpoint

    def url(app:)
      config_key = "#{app}_url".to_sym
      Rails.application.config.parity_check[config_key] + path
    end

    def headers
      {
        "Authorization" => "Bearer #{token_provider.token(lead_provider:)}",
        "Accept" => "application/json",
        "Content-Type" => "application/json",
      }
    end

  private

    def token_provider
      @token_provider ||= TokenProvider.new
    end
  end
end
