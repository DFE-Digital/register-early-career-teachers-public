RSpec.describe API::Request do
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:token) { API::TokenManager.create_lead_provider_api_token!(lead_provider:).token }

  before do
    allow(DfE::Analytics::SendEvents).to receive(:do)
  end

  describe ".send_persist_api_request" do
    let(:uuid) { SecureRandom.uuid }
    let(:created_at) { "2025-08-22T12:00:00Z" }

    let(:request_data) do
      {
        path: "/api/v3/endpoints",
        method: "POST",
        params: { "foo" => "bar" },
        body: '{"foo":"bar"}',
        headers: {
          "HTTP_AUTHORIZATION" => "Bearer #{token}",
        }
      }
    end

    let(:response_data) do
      {
        headers: { "Content-Type" => "application/json" },
        body: { message: "Success" }.to_json
      }
    end

    context "dfe_analytics is enabled" do
      before do
        stub_const("ENV", "DFE_ANALYTICS_ENABLED" => "true")
      end

      context "when authorization header is missing" do
        it "does not send an event" do
          request_data[:headers].delete("HTTP_AUTHORIZATION")

          described_class.send_persist_api_request(request_data, response_data, 200, created_at, uuid)

          expect(DfE::Analytics::SendEvents).not_to have_received(:do).with(
            array_including(hash_including("event_type" => "persist_api_request"))
          )
        end
      end

      context "when authorization token is invalid" do
        it "does not send an event" do
          request_data[:headers]["HTTP_AUTHORIZATION"] = "Bearer invalid-token"

          described_class.send_persist_api_request(request_data, response_data, 200, created_at, uuid)

          expect(DfE::Analytics::SendEvents).not_to have_received(:do).with(
            array_including(hash_including("event_type" => "persist_api_request"))
          )
        end
      end

      context "when all data is valid" do
        it "sends a persist_api_request event with correct structure" do
          described_class.send_persist_api_request(request_data, response_data, 200, created_at, uuid)

          expect(DfE::Analytics::SendEvents).to have_received(:do).with(
            array_including(hash_including("event_type" => "persist_api_request"))
          ) do |events|
            event = events.find { |entry| entry["event_type"] == "persist_api_request" }

            expect(event).to include(
              "event_type" => "persist_api_request",
              "request_uuid" => uuid,
              "entity_table_name" => "api_requests",
              "user_id" => lead_provider.id
            )

            data = event["data"]

            expect(data).to include(
              { "key" => "request_path", "value" => ["/api/v3/endpoints"] },
              { "key" => "request_method", "value" => %w[POST] },
              { "key" => "status_code", "value" => [200] },
              hash_including("key" => "lead_provider", "value" => [lead_provider.to_json]),
              { "key" => "request_body", "value" => ['{"foo":"bar"}'] }
            )
          end
        end
      end

      context "when response body is not valid JSON and status is > 299" do
        it "adds fallback error in response body" do
          response_data[:body] = "Not JSON"

          described_class.send_persist_api_request(request_data, response_data, 500, created_at, uuid)

          expect(DfE::Analytics::SendEvents).to have_received(:do).with(
            array_including(hash_including("event_type" => "persist_api_request"))
          ) do |events|
            event = events.find { |entry| entry["event_type"] == "persist_api_request" }
            data_array = event["data"]

            response_body_entry = data_array.find { |entry| entry["key"] == "response_body" }

            expect(response_body_entry).not_to be_nil
            expect(response_body_entry["value"]).to eq([{ "body" => "500 did not respond with JSON" }.to_json])
          end
        end
      end

      context "when request body is not valid JSON" do
        it "adds error fallback for request_body" do
          request_data[:body] = "invalid json"

          described_class.send_persist_api_request(request_data, response_data, 200, created_at, uuid)

          expect(DfE::Analytics::SendEvents).to have_received(:do).with(
            array_including(hash_including("event_type" => "persist_api_request"))
          ) do |events|
            event = events.find { |entry| entry["event_type"] == "persist_api_request" }
            data_array = event["data"]

            request_body_entry = data_array.find { |entry| entry["key"] == "request_body" }

            expect(request_body_entry).not_to be_nil
            expect(request_body_entry["value"]).to eq([{ error: "request data did not contain valid JSON" }.to_json])
          end
        end
      end
    end

    context "dfe_analytics by default disabled" do
      it "does not send events" do
        expect {
          described_class.send_persist_api_request(request_data, response_data, 200, created_at, uuid)
        }.not_to raise_error

        expect(DfE::Analytics::SendEvents).not_to have_received(:do)
      end
    end
  end

  describe ".send_throttled_request" do
    let(:env) do
      {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/api/v3/endpoints",
        "HTTP_AUTHORIZATION" => "Bearer #{token}",
        "rack.session" => {}
      }
    end

    context "dfe_analytics is enabled" do
      before do
        stub_const("ENV", "DFE_ANALYTICS_ENABLED" => "true")
      end

      it "sends a throttled web_request event with user if available" do
        described_class.send_throttled_request(env)

        expected_values = {
          "event_type" => "web_request",
          "response_status" => 429,
          "request_path" => "/api/v3/endpoints",
          "user_id" => lead_provider.id
        }
        expect(DfE::Analytics::SendEvents).to have_received(:do).with(array_including(hash_including(expected_values)))
      end
    end

    context "dfe_analytics by default disabled" do
      it "does not send events" do
        described_class.send_throttled_request(env)

        expect(DfE::Analytics::SendEvents).not_to have_received(:do)
      end
    end
  end
end
