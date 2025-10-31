describe API::StatementSerializer, type: :serializer do
  subject(:response) { JSON.parse(described_class.render(statement)) }

  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }
  let(:contract_period) { FactoryBot.create(:contract_period, year: 2024) }
  let!(:statement) do
    FactoryBot.create(
      :statement,
      active_lead_provider:,
      api_id: "fe1a5280-1b13-4b09-b9c7-e2b01d37e851",
      month: 7,
      year: 2023,
      deadline_date: Date.new(2023, 7, 1),
      payment_date: Date.new(2023, 7, 1),
      created_at:,
      api_updated_at:
    )
  end
  let(:created_at) { Time.utc(2023, 7, 1, 12, 0, 0) }
  let(:api_updated_at) { Time.utc(2023, 7, 2, 12, 0, 0) }

  describe "core attributes" do
    it "serializes correctly" do
      expect(response["id"]).to eq("fe1a5280-1b13-4b09-b9c7-e2b01d37e851")
      expect(response["type"]).to eq("statement")
    end
  end

  describe "nested attributes" do
    subject(:attributes) { response["attributes"] }

    it "serializes correctly" do
      expect(attributes["cohort"]).to eq("2024")
      expect(attributes["month"]).to eq("July")
      expect(attributes["year"]).to eq("2023")
      expect(attributes["cut_off_date"]).to eq("2023-07-01")
      expect(attributes["payment_date"]).to eq("2023-07-01")
      expect(attributes["created_at"]).to eq(created_at.utc.rfc3339)
      expect(attributes["updated_at"]).to eq(api_updated_at.utc.rfc3339)
    end

    describe "`paid` status" do
      it "returns `true` when status is `paid`" do
        statement.status = :paid

        expect(attributes["paid"]).to be(true)
      end

      it "returns `false` when `state` is not `paid`" do
        statement.status = :open

        expect(attributes["paid"]).to be(false)
      end
    end
  end
end
