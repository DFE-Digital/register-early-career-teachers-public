module ParityCheck
  class Client
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :request

    def perform_requests
      loop do
        ecf_response, ecf_response_time_ms = timed_response { perform_request(app: :ecf) }
        rect_response, rect_response_time_ms = timed_response { perform_request(app: :rect) }

        response = Response.new(
          ecf_body: ecf_response.body,
          ecf_status_code: ecf_response.code,
          ecf_time_ms: ecf_response_time_ms,
          rect_body: rect_response.body,
          rect_status_code: rect_response.code,
          rect_time_ms: rect_response_time_ms,
          page: request_builder.page
        )

        yield(response)

        break unless request_builder.advance_page(response)
      end
    end

  private

    def timed_response
      response = nil
      response_time_ms = Benchmark.realtime { response = yield } * 1_000

      [response, response_time_ms]
    end

    def perform_request(app:)
      HTTParty.send(
        request_builder.method,
        request_builder.url(app:),
        headers: request_builder.headers,
        query: request_builder.query,
        body: request_builder.body
      )
    end

    def request_builder
      @request_builder ||= RequestBuilder.new(request:)
    end
  end
end
