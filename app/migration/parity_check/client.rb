require "async/http/faraday/default"

module ParityCheck
  class Client
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :request

    def perform_requests
      loop do
        ecf_response, rect_response = nil

        connection.in_parallel do
          ecf_response = perform_request(app: :ecf)
          rect_response = perform_request(app: :rect)
        end

        response = Response.new(
          ecf_body: ecf_response.body,
          ecf_status_code: ecf_response.status,
          ecf_time_ms: ecf_response.env[:request_duration_ms],
          rect_body: rect_response.body,
          rect_status_code: rect_response.status,
          rect_time_ms: rect_response.env[:request_duration_ms],
          page: request_builder.page
        )

        yield(response)

        break unless request_builder.advance_page(response)
      end
    end

  private

    def perform_request(app:)
      connection.send(request_builder.method) do |request|
        request.url request_builder.url(app:), request_builder.query
        request.headers = request_builder.headers
        request.body = request_builder.body if request_builder.body
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
