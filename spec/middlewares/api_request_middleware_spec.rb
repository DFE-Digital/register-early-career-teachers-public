RSpec.describe APIRequestMiddleware do
  subject { described_class.new(mock_app) }

  let(:status) { 200 }
  let(:request) { Rack::MockRequest.new(subject) }
  let(:headers) { { "HEADER" => "Yeah!" } }
  let(:mock_response) { ["Hellowwworlds!"] }
  let(:mock_request_uuid) { "9f170ae9-2fd5-42b6-869f-08e5064c52a3" }

  let(:mock_app) do
    ->(_env) do
      [status, headers, mock_response]
    end
  end

  before do
    stub_const('ENV', 'DFE_ANALYTICS_ENABLED' => "true")

    allow(APIRequestJob).to receive(:perform_later)
    allow(RequestLocals).to receive(:fetch).with(:dfe_analytics_request_id).and_return(mock_request_uuid)
  end

  describe "#call on a non-API path" do
    it "does not fire APIRequestJob" do
      request.get "/"

      expect(APIRequestJob).not_to have_received(:perform_later)
    end
  end

  describe "#call on an API path" do
    it "fires an APIRequestJob" do
      request.get "/api/v3/statements", params: { foo: "bar" }

      request_data = hash_including("body", "headers", "path" => "/api/v3/statements", "params" => { "foo" => "bar" }, "method" => "GET")
      response_data = hash_including("body", "headers")
      expect(APIRequestJob).to have_received(:perform_later).with(request_data, response_data, status, anything, mock_request_uuid)
    end
  end

  # TODO: add this once we have a POST endpoint ready
  # describe "#call on an API path with POST data" do
  #   it "fires an APIRequestJob including post data" do
  #     request.post "/api/v1/participant-declarations", as: :json, params: { foo: "bar" }.to_json
  #
  #     expect(APIRequestJob).to have_received(:perform_later).with(
  #       hash_including("path" => "/api/v1/participant-declarations", "body" => '{"foo":"bar"}', "method" => "POST"), anything, 200, anything, anything
  #     )
  #   end
  # end

  describe "#call on an API path when an exception happens in the job" do
    it "logs the exception and returns" do
      allow(Rails.logger).to receive(:warn)
      allow(APIRequestJob).to receive(:perform_later).and_raise(StandardError)

      request.get "/api/v3/statements"

      expect(Rails.logger).to have_received(:warn)
    end
  end
end
