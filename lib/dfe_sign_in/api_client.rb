module DfESignIn
  class APIClient
    class DfESignIn::APIClient::DfESignInDisabled < StandardError; end

    attr_reader :connection

    DEFAULT_TIMEOUT = 3

    def initialize(url: base_url, timeout: DEFAULT_TIMEOUT)
      fail(DfESignInDisabled) unless Rails.application.config.dfe_sign_in_enabled

      @connection = Faraday.new(url:, request: { timeout: }) do |faraday|
        faraday.request(:authorization, 'Bearer', jwt)
        faraday.request(:json)
        faraday.response(:json)
      end
    end

    def organisations(user_id:)
      path = %(/users/#{user_id}/organisations)

      response = @connection.get(path)

      if response.success?
        Organisation.from_response_body(response.body)
      else
        raise "API request failed: #{response.status} #{response.body}"
      end
    end

    def access_levels(organisation_id:, user_id:, service_id: client_id)
      path = %(services/#{service_id}/organisations/#{organisation_id}/users/#{user_id})

      response = @connection.get(path)

      if response.success?
        AccessLevel.from_response_body(response.body)
      else
        raise "API request failed: #{response.status} #{response.body}"
      end
    end

  private

    def jwt
      @jwt ||= JWT.encode({ iss: client_id, aud: audience }, secret, 'HS256')
    end

    def base_url
      ENV.fetch('DFE_SIGN_IN_API_BASE_URL')
    end

    def client_id
      ENV.fetch('DFE_SIGN_IN_CLIENT_ID')
    end

    def audience
      ENV.fetch('DFE_SIGN_IN_API_AUDIENCE')
    end

    def secret
      ENV.fetch('DFE_SIGN_IN_API_SECRET')
    end
  end
end
