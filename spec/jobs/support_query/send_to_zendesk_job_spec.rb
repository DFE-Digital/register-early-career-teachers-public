RSpec.describe SupportQuery::SendToZendeskJob do
  describe "#perform" do
    let(:support_query) { FactoryBot.create(:support_query) }

    it "sends the support query to Zendesk" do
      expect(support_query).to receive(:send_to_zendesk_now)

      SupportQuery::SendToZendeskJob.perform_now(support_query)
    end
  end
end
