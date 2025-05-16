module Helpers
  module APIHelpers
    def api_get(url, params: {}, headers: {}, token: nil)
      token ||= lead_provider_token
      headers ||= {}
      headers["Authorization"] = "Bearer #{token}"

      get url, params:, headers:
    end

    def api_post(url, params: {}, headers: {}, token: nil)
      token ||= lead_provider_token
      headers ||= {}
      headers["Authorization"] = "Bearer #{token}"
      headers["Content-Type"] = "application/json"

      post url, params: params.to_json, headers:
    end

    def api_put(url, params: {}, headers: {}, token: nil)
      token ||= lead_provider_token
      headers ||= {}
      headers["Authorization"] = "Bearer #{token}"
      headers["Content-Type"] = "application/json"

      put url, params: params.to_json, headers:
    end

    # TODO: Removed this method for now, put it back in when we need it
    # def parsed_response
    #   Oj.load(response.body)
    # end

    def lead_provider_token
      lead_provider = current_lead_provider if defined?(current_lead_provider)
      lead_provider ||= FactoryBot.create(:lead_provider)

      APIToken.create_with_random_token!(lead_provider:, scope: "lead_provider")
    end
  end
end
