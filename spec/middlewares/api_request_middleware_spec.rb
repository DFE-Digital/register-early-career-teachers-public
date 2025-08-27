RSpec.describe APIRequestMiddleware do
  subject(:middleware) { described_class.new(mock_app) }

  let(:request) { Rack::MockRequest.new(middleware) }
  let(:status) { 200 }
  let(:headers) { { "Content-Type" => "application/json" } }
  let(:mock_response) { %w[Success] }
  let(:mock_request_uuid) { "9f170ae9-2fd5-42b6-869f-08e5064c52a3" }

  let(:mock_app) do
    ->(_env) do
      [status, headers, mock_response]
    end
  end

  before do
    stub_const('ENV', 'DFE_ANALYTICS_ENABLED' => "true")

    allow(APIRequest).to receive(:send_persist_api_request)
    allow(RequestLocals).to receive(:fetch).with(:dfe_analytics_request_id).and_return(mock_request_uuid)
  end

  describe "#call on a non-API path" do
    it "does not fire APIRequest" do
      request.get "/"

      expect(APIRequest).not_to have_received(:send_persist_api_request)
    end
  end

  describe "#call on an API path" do
    it "fires an APIRequest" do
      request.get "/api/v3/statements", params: { foo: "bar" }

      request_data = hash_including("body", "headers", "path" => "/api/v3/statements", "params" => { "foo" => "bar" }, "method" => "GET")
      response_data = hash_including("body", "headers")
      expect(APIRequest).to have_received(:send_persist_api_request).with(request_data, response_data, status, anything, mock_request_uuid)
    end
  end

  describe "#call on an API path with POST data" do
    it "fires an APIRequest including post data" do
      request.post "/api/v3/partnerships", input: { foo: "bar" }.to_json, 'CONTENT_TYPE' => 'application/json'

      request_data = hash_including("headers", "path" => "/api/v3/partnerships", "method" => "POST", "body" => '{"foo":"bar"}')
      response_data = hash_including("body", "headers")
      expect(APIRequest).to have_received(:send_persist_api_request).with(request_data, response_data, status, anything, mock_request_uuid)
    end
  end

  describe "#call on an API path when an exception happens in the job" do
    it "logs the exception and returns" do
      allow(Rails.logger).to receive(:warn)
      allow(APIRequest).to receive(:send_persist_api_request).and_raise(StandardError)

      request.get "/api/v3/statements"

      expect(Rails.logger).to have_received(:warn)
    end
  end
end
