class APIRequest
  class << self
    def send_persist_api_request(request_data, response_data, status_code, created_at, uuid)
      return unless DfE::Analytics.enabled?

      request_data = request_data.with_indifferent_access
      response_data = response_data.with_indifferent_access
      request_headers = request_data.fetch(:headers, {})

      lead_provider = fetch_lead_provider(request_headers.delete("HTTP_AUTHORIZATION"))
      return unless lead_provider

      response_headers = response_data[:headers]
      response_body = response_data[:body]

      data = {
        request_path: request_data[:path],
        request_headers:,
        request_body: request_body(request_data),
        request_method: request_data[:method],
        response_headers:,
        response_body: response_hash(response_body, status_code),
        status_code:,
        user_description: user_description(lead_provider),
        lead_provider:,
        created_at:,
      }

      event = DfE::Analytics::Event.new
        .with_type(:persist_api_request)
        .with_request_uuid(uuid)
        .with_entity_table_name(:api_requests)
        .with_data(data:)
        .with_user(lead_provider)

      DfE::Analytics::SendEvents.do(Array.wrap(event.as_json))
    end

    def send_throttled_request(env)
      return unless DfE::Analytics.enabled?

      request = ActionDispatch::Request.new(env)
      response = ActionDispatch::Response.new(429)

      user = fetch_user(request.session)
      user ||= fetch_lead_provider(request.authorization)

      rate_limit_event = DfE::Analytics::Event.new
        .with_type(:web_request)
        .with_request_uuid(request.uuid)
        .with_request_details(request)
        .with_response_details(response)

      rate_limit_event.with_user(user) if user

      DfE::Analytics::SendEvents.do([rate_limit_event.as_json])
    end

  private

    def response_hash(response_body, status)
      return {} unless status > 299
      return {} unless response_body

      JSON.parse(response_body)
    rescue JSON::ParserError
      { body: "#{status} did not respond with JSON" }
    end

    def request_body(request_data)
      if request_data[:body].present?
        JSON.parse(request_data[:body])
      else
        request_data[:params]
      end
    rescue JSON::ParserError
      { error: "request data did not contain valid JSON" }
    end

    def fetch_user(session)
      # Fetch user from session
      Sessions::User.from_session(session["user_session"])
    end

    def fetch_lead_provider(http_authorization)
      token = http_authorization.to_s.split("Bearer ").last
      return if token.blank?

      ::API::TokenManager.find_lead_provider_api_token(token:)&.lead_provider
    end

    def user_description(lead_provider)
      return unless lead_provider

      "Lead provider: #{lead_provider.name}"
    end
  end
end
