module ParityCheck
  class Client
    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_accessor :ecf_result, :rect_result

    attribute :request_builder, default: -> { RequestBuilder.new }
    attribute :ecf_url, default: -> { ENV.fetch('ECF_URL', 'https://ecf.example.com') }
    attribute :rect_url, default: -> { ENV.fetch('RECT_URL', 'https://rect.example.com') }

    attribute :endpoint
    attribute :lead_provider

    def perform_requests
      ecf_result = timed_response { perform_request(app: :ecf) }
      rect_result = timed_response { perform_request(app: :rect) }

      yield(ecf_result, rect_result)
    end

  private

    def timed_response
      response = nil
      response_time_ms = Benchmark.realtime { response = yield } * 1_000

      { response:, response_time_ms: }
    end

    def perform_request(app:)
      HTTParty.send(request_builder.method, request_builder.url(app:), headers: request_builder.headers)
    end

    def request_builder
      @request_builder ||= RequestBuilder.new(endpoint:, lead_provider:)
    end
  end
end
