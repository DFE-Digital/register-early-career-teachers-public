class APIRequestJob < ApplicationJob
  def perform(request_data, response_data, status_code, created_at, uuid)
    request_data = request_data.with_indifferent_access
    response_data = response_data.with_indifferent_access
    request_headers = request_data.fetch(:headers, {})
    lead_provider = fetch_lead_provider(request_headers.delete("HTTP_AUTHORIZATION"))

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

    send_analytics_event(lead_provider:, data:, uuid:)
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

  def fetch_lead_provider(http_authorization)
    token = http_authorization.to_s.split("Bearer ").last
    return if token.blank?

    ::API::TokenManager.find_lead_provider_api_token(token:)&.lead_provider
  end

  def user_description(lead_provider)
    return unless lead_provider

    "Lead provider: #{lead_provider.name}"
  end

  def send_analytics_event(lead_provider:, data:, uuid:)
    return if lead_provider.blank?

    event = DfE::Analytics::Event.new
      .with_type(:persist_api_request)
      .with_request_uuid(uuid)
      .with_entity_table_name(:api_requests)
      .with_data(data:)
      .with_user(lead_provider)

    DfE::Analytics::SendEvents.do(Array.wrap(event.as_json))
  end
end
