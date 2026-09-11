module API::OAuth::AuthorizationRequest::Redirectable
  extend ActiveSupport::Concern

  ERROR_CODES = {
    %i[response_type inclusion] => :unsupported_response_type,
    %i[appropriate_body_period_id equal_to] => :access_denied,
  }.freeze

  def redirectable? = redirect_uri.present? && client&.redirect_uris&.include?(redirect_uri)

  def successful_redirect_uri(code:) = build_redirect_url(code:)

  def unsuccessful_redirect_uri(error: error_code, error_description: error_messages_description)
    build_redirect_url(error:, error_description:)
  end

  def error_code
    return if errors.empty?

    ERROR_CODES.find { |(attribute, kind), _| errors.of_kind?(attribute, kind) }&.last || :invalid_request
  end

private

  def build_redirect_url(**response_params)
    uri = URI.parse(redirect_uri)
    existing_query_params = uri.query.present? ? URI.decode_www_form(uri.query).to_h : {}
    state_params = { state: state.presence }
    query_params = existing_query_params.merge(response_params).merge(state_params).compact
    uri.query = URI.encode_www_form(query_params)
    uri.to_s
  end

  def error_messages_description = errors.full_messages.join(", ")
end
