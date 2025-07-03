shared_examples "an index endpoint" do
  context "when 2 resources exist for the lead provider" do
    let!(:resources) do
      [
        create_resource(active_lead_provider:),
        create_resource(active_lead_provider:)
      ]
    end

    before do
      # Resource for a different lead provider.
      lead_provider = FactoryBot.create(:lead_provider, name: "Other Lead Provider")
      contract_period = active_lead_provider.contract_period
      create_resource(active_lead_provider: FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:))
    end

    it "returns the correct resources in a serialized format" do
      authenticated_api_get(path)

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eql("application/json; charset=utf-8")
      expect(response.body).to eq(serializer.render(apply_expected_order(resources), root: "data"))
    end
  end

  context "when no resources exist for the lead provider" do
    it "returns an empty result in serialized format" do
      authenticated_api_get(path)

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eql("application/json; charset=utf-8")
      expect(response.body).to eq(serializer.render([], root: "data"))
    end
  end
end
