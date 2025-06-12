module ParityCheck
  class Client
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :endpoint

    def perform_requests
      ecf_result = timed_response { send("#{request_builder.method}_request", app: :ecf) }
      rect_result = timed_response { send("#{request_builder.method}_request", app: :rect) }

      yield(ecf_result, rect_result)
    end

  private

    def timed_response
      response = nil
      response_time_ms = Benchmark.realtime { response = yield } * 1_000

      { response:, response_time_ms: }
    end

    def get_request(app:)
      HTTParty.get(request_builder.url(app:), headers: request_builder.headers)
    end

    def request_builder
      @request_builder ||= RequestBuilder.new(endpoint:)
    end
  end
end
