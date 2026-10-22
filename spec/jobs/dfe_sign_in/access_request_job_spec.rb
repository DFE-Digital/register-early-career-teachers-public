RSpec.describe DfESignIn::AccessRequestJob do
  describe "#perform_now" do
    subject(:perform_now) do
      described_class.perform_now(organisation_id:, user_id:, role_ids:)
    end

    let(:organisation_id) { SecureRandom.uuid }
    let(:user_id) { SecureRandom.uuid }
    let(:role_ids) { [SecureRandom.uuid] }

    let(:api_client) { DfESignIn::APIClient.new }
    let(:connection) { api_client.instance_variable_get(:@connection) }
    let(:faraday_response) do
      instance_double(Faraday::Response, success?: success, status:, body:)
    end

    before do
      stub_const("ENV", {
        "DFE_SIGN_IN_API_BASE_URL" => "http://api.example.com",
        "DFE_SIGN_IN_CLIENT_ID" => "SomeService",
        "DFE_SIGN_IN_API_AUDIENCE" => "signin.example.com",
        "DFE_SIGN_IN_API_SECRET" => "ABC123",
      })
      allow(DfESignIn::APIClient).to receive(:new).and_return(api_client)
      allow(connection).to receive(:post).and_return(faraday_response)
    end

    context "when the API client returns a successful response" do
      let(:success) { true }
      let(:status) { 202 }
      let(:body) { { message: "Success!" } }

      it "calls the API client with the correct parameters" do
        expect(api_client)
          .to receive(:access_requests)
          .with(organisation_id:, user_id:, role_ids:)
          .once

        perform_now
      end

      it "does not capture an exception in Sentry" do
        expect(Sentry).not_to receive(:capture_exception)

        perform_now
      end

      it "does not retry the job" do
        expect { perform_now }.not_to have_enqueued_job(described_class)
      end
    end

    context "when the API returns a 403 response" do
      let(:success) { false }
      let(:status) { 403 }
      let(:body) { { "error" => "Forbidden" } }

      it "calls the API client with the correct parameters" do
        expect(api_client)
          .to receive(:access_requests)
          .with(organisation_id:, user_id:, role_ids:)
          .once

        perform_now
      end

      it "captures the exception in Sentry" do
        expect(Sentry)
          .to receive(:capture_exception)
          .with(instance_of(DfESignIn::APIClient::ForbiddenError), level: :error)

        perform_now
      end

      it "does not retry the job" do
        expect { perform_now }.not_to have_enqueued_job(described_class)
      end
    end

    context "when the API returns a 404 response" do
      let(:success) { false }
      let(:status) { 404 }
      let(:body) { { "error" => "NotFound" } }

      it "calls the API client with the correct parameters" do
        expect(api_client)
          .to receive(:access_requests)
          .with(organisation_id:, user_id:, role_ids:)
          .once

        perform_now
      end

      it "captures the exception in Sentry" do
        expect(Sentry)
          .to receive(:capture_exception)
          .with(instance_of(DfESignIn::APIClient::NotFoundError), level: :error)

        perform_now
      end

      it "does not retry the job" do
        expect { perform_now }.not_to have_enqueued_job(described_class)
      end
    end

    context "when the API returns a different 4XX response" do
      let(:success) { false }
      let(:status) { 418 }
      let(:body) { { "error" => "I'm a teapot" } }

      it "calls the API client with the correct parameters" do
        expect(api_client)
          .to receive(:access_requests)
          .with(organisation_id:, user_id:, role_ids:)
          .once

        perform_now
      end

      it "captures the exception in Sentry" do
        expect(Sentry)
          .to receive(:capture_exception)
          .with(instance_of(DfESignIn::APIClient::ResponseError), level: :error)

        perform_now
      end

      it "does not retry the job" do
        expect { perform_now }.not_to have_enqueued_job(described_class)
      end
    end

    context "when the API returns a 500 response" do
      let(:success) { false }
      let(:status) { 500 }
      let(:body) { { "error" => "InternalServerError" } }

      it "calls the API client with the correct parameters" do
        expect(api_client)
          .to receive(:access_requests)
          .with(organisation_id:, user_id:, role_ids:)
          .once

        perform_now
      end

      it "does not capture an exception in Sentry" do
        expect(Sentry).not_to receive(:capture_exception)

        perform_now
      end

      it "retries the job" do
        expect { perform_now }.to have_enqueued_job(described_class)
      end
    end
  end
end
