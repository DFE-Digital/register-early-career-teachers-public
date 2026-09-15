describe API::OAuth::Authorizations::Revoke do
  subject(:service) { described_class.new(authorization:) }

  let(:client) { FactoryBot.create(:api_oauth_client) }
  let!(:authorization) do
    FactoryBot.create(:api_oauth_authorization, client:, code_verifier:).tap { it.exchange_code_for_token!(code_verifier:) }
  end

  let(:code_verifier) { "secret" }
  let(:token) { authorization.token }
  let(:appropriate_body_period) { authorization.appropriate_body_period }

  describe "#revoke!" do
    it "revokes the authorization" do
      service.revoke!

      expect(authorization.reload).to be_revoked
    end

    it "sets revoked_at to the current time and date" do
      freeze_time do
        service.revoke!

        expect(authorization.reload.revoked_at).to eq Time.zone.now
      end
    end

    it "generates an event" do
      freeze_time do
        expect {
          service.revoke!
        }.to have_enqueued_job(RecordEventJob).with(
          author_name: authorization.client.name,
          author_type: :oauth_client,
          event_type: :api_oauth_authorization_revoked,
          happened_at: Time.zone.now,
          appropriate_body_period:,
          heading: "Authorization revoked by client '#{client.name}' for '#{appropriate_body_period.name}'"
        )
      end
    end

    it "the queued job adds an event record when performed" do
      expect {
        perform_enqueued_jobs { service.revoke! }
      }.to change(Event, :count).by(1)

      expect(Event.first.event_type).to eq "api_oauth_authorization_revoked"
    end

    context "when the authorization is already revoked" do
      before do
        travel_to(1.week.ago) do
          authorization.revoke!
        end
        authorization.reload
      end

      it "does not change the revoked_at" do
        expect {
          service.revoke!
        }.not_to change(authorization, :revoked_at)
      end
    end
  end
end
