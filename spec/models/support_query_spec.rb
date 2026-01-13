RSpec.describe SupportQuery do
  let(:support_query) { FactoryBot.create(:support_query) }

  before do
    stub_const("ENV", {
      "ZENDESK_URL" => "https://example.com",
      "ZENDESK_USERNAME" => "test",
      "ZENDESK_TOKEN" => "test",
    })
  end

  describe "#send_to_zendesk_now" do
    context "when Zendesk works as expected" do
      let(:zendesk_ticket_id) { 123_456 }

      before do
        ticket = double(id: zendesk_ticket_id)
        allow(ZendeskAPI::Ticket).to receive(:create!).and_return(ticket)
      end

      it "sends the ticket to Zendesk and updates state" do
        support_query.send_to_zendesk_now

        expect(ZendeskAPI::Ticket).to have_received(:create!).with(
          instance_of(ZendeskAPI::Client),
          hash_including(
            tags: %w[rect-web-form-support-query],
            requester: {
              name: support_query.name,
              email: support_query.email
            },
            description: <<~TEXT
              #{support_query.message}

              ---

              School name: #{support_query.school_name}
              School URN: #{support_query.school_urn}
            TEXT
          )
        )

        expect(support_query.zendesk_id).to eq(zendesk_ticket_id)
        expect(support_query).to be_sent
      end
    end

    context "when the Zendesk API returns an errors" do
      before do
        allow(ZendeskAPI::Ticket).to receive(:create!).and_raise(StandardError.new("boom"))
      end

      it "marks the support query as failed" do
        expect { support_query.send_to_zendesk_now }.to raise_error(StandardError, "boom")

        expect(support_query).to be_failed
      end
    end

    context "when it has already been sent" do
      let(:support_query) { FactoryBot.create(:support_query, :sent) }

      it "raises an exception without sending the ticket to Zendesk" do
        expect(ZendeskAPI::Ticket).not_to receive(:create!)
        expect { support_query.send_to_zendesk_now }.to raise_error(StateMachines::InvalidTransition)
      end
    end
  end
end
