module ParityCheck
  class RequestBuilder
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ParityCheck::Configuration

    class Error < RuntimeError; end
    class IDOptionMissingError < Error; end
    class UnrecognizedQueryError < Error; end

    PLACEHOLDER_PATTERN = /:[a-z_]+/
    PAGINATION_PER_PAGE = 100

    attribute :request

    delegate :lead_provider, :endpoint, to: :request
    delegate :method, :path, :options, to: :endpoint

    def url(app:)
      parity_check_url(app:) + formatted_path(app:)
    end

    def headers
      {
        "Authorization" => "Bearer #{token_provider.token(lead_provider:)}",
        "Accept" => "application/json",
        "Content-Type" => "application/json"
      }
    end

    def body
      identifier = options[:body]

      return unless identifier

      dynamic_request_content.fetch(identifier).to_json
    end

    def query
      options_query.merge(pagination_query)
    end

    def page
      return unless pagination_enabled?

      @page ||= 1
    end

    def advance_page(previous_response)
      pages_remain?(previous_response) && @page = page + 1
    end

    private

    def app_specific_path(app:)
      options[:"#{app}_path"] || path
    end

    def populate_placeholder(value)
      return value unless PLACEHOLDER_PATTERN.match?(value.to_s)

      dynamic_request_content.fetch(value.delete_prefix(":"))
    end

    def formatted_path(app:)
      app_specific_path = app_specific_path(app:)

      return app_specific_path unless PLACEHOLDER_PATTERN.match?(app_specific_path)

      app_specific_path.sub(":id", path_id)
    end

    def path_id
      identifier = options[:id]

      raise IDOptionMissingError, "Path contains ID, but options[:id] is missing" unless identifier

      populate_placeholder(identifier)
    end

    def token_provider
      @token_provider ||= TokenProvider.new
    end

    def options_query
      options_query = options[:query]

      return {} unless options_query

      raise UnrecognizedQueryError, "Query must be a Hash: #{options_query}" unless options_query.is_a?(Hash)

      options_query.deep_transform_values { |v| populate_placeholder(v) }
    end

    def pagination_query
      return {} unless pagination_enabled?

      {page: {page:, per_page: PAGINATION_PER_PAGE}}
    end

    def pages_remain?(previous_response)
      return false unless pagination_enabled?

      [previous_response.ecf_body_hash, previous_response.rect_body_hash].compact.any? do |body|
        body[:data]&.size == PAGINATION_PER_PAGE
      rescue JSON::ParserError
        false
      end
    end

    def pagination_enabled?
      ActiveRecord::Type::Boolean.new.cast(options[:paginate])
    end

    def dynamic_request_content
      @dynamic_request_content ||= DynamicRequestContent.new(lead_provider:)
    end
  end
end
