module ParityCheck
  class Client
    include ActiveModel::Model
    include ActiveModel::Attributes

    class Error < RuntimeError; end
    class RequestError < Error; end

    REQUEST_ERRORS = [
      DynamicRequestContent::Error,
      RequestBuilder::Error,
      TokenProvider::Error,
      NoMethodError
    ].freeze

    attribute :request

    def perform_requests
      loop do
        ecf_response, rect_response = nil

        connection.in_parallel do
          ecf_response = perform_request(app: :ecf)
          rect_response = perform_request(app: :rect)
        end

        raise RequestError, "Constructed requests do not match between ECF and RECT" unless requests_consistent?(ecf_response, rect_response)

        response = build_response(ecf_response, rect_response)
        next_page = request_builder.advance_page(response)

        response.save!

        break unless next_page
      end
    rescue *REQUEST_ERRORS => e
      raise RequestError, e.message
    end

  private

    def requests_consistent?(ecf_response, rect_response)
      return false unless %i[method request_body request_headers].all? { ecf_response.env[it] == rect_response.env[it] }
      return false unless ecf_response.env[:url].query == rect_response.env[:url].query

      true
    end

    def build_response(ecf_response, rect_response)
      Response.new(
        request:,
        ecf_body: ecf_response.body,
        ecf_status_code: ecf_response.status,
        ecf_time_ms: ecf_response.env[:request_duration_ms],
        rect_body: rect_response.body,
        rect_status_code: rect_response.status,
        rect_time_ms: rect_response.env[:request_duration_ms],
        ecf_request_uri: CGI.unescape(ecf_response.env[:url].request_uri),
        rect_request_uri: CGI.unescape(rect_response.env[:url].request_uri),
        request_body: rect_response.env[:request_body],
        page: request_builder.page
      )
    end

    def perform_request(app:)
      connection.send(request_builder.method) do |request|
        request.url request_builder.url(app:), request_builder.query
        request_builder.headers.tap { request.headers = it if it.present? }
        request_builder.body.tap { request.body = it if it.present? }
      end
    end

    def request_builder
      @request_builder ||= RequestBuilder.new(request:)
    end

    def connection
      @connection ||= Faraday::Connection.new do
        it.adapter :async_http
        it.use RequestBenchmark
      end
    end
  end
end
