describe StatementSerializer, type: :serializer do
  let(:active_lead_provider) { FactoryBot.build(:active_lead_provider) }
  let(:statement) { FactoryBot.build(:statement, active_lead_provider:) }

  describe "core attributes" do
    subject(:response) { JSON.parse(described_class.render(statement)) }

    it "serializes `id`" do
      statement.api_id = "fe1a5280-1b13-4b09-b9c7-e2b01d37e851"

      expect(response["id"]).to eq("fe1a5280-1b13-4b09-b9c7-e2b01d37e851")
    end

    it "serializes `type`" do
      response = JSON.parse(described_class.render(statement))

      expect(response["type"]).to eq("statement")
    end
  end

  describe "nested attributes" do
    subject(:attributes) { JSON.parse(described_class.render(statement))["attributes"] }

    it "serializes `cohort`" do
      active_lead_provider.registration_period.year = 2025

      expect(attributes["cohort"]).to eq("2025")
    end

    it "serializes `month`" do
      statement.month = 7

      expect(attributes["month"]).to eq("July")
    end

    it "serializes `year`" do
      statement.year = 2023

      expect(attributes["year"]).to eq("2023")
    end

    it "serializes `cut_off_date`" do
      statement.deadline_date = Date.new(2023, 7, 1)

      expect(attributes["cut_off_date"]).to eq("2023-07-01")
    end

    it "serializes `payment_date`" do
      statement.payment_date = Date.new(2023, 7, 1)

      expect(attributes["payment_date"]).to eq("2023-07-01")
    end

    describe "`paid` status" do
      it "returns `true` when state is `paid`" do
        statement.state = :paid

        expect(attributes["paid"]).to be(true)
      end

      it "returns `false` when `state` is not `paid`" do
        statement.state = :open

        expect(attributes["paid"]).to be(false)
      end
    end

    describe "timestamp serialization" do
      it "serializes `created_at`" do
        statement.created_at = Time.utc(2023, 7, 1, 12, 0, 0)

        expect(attributes["created_at"]).to eq("2023-07-01T12:00:00Z")
      end

      it "serializes `updated_at`" do
        statement.updated_at = Time.utc(2023, 7, 2, 12, 0, 0)

        expect(attributes["updated_at"]).to eq("2023-07-02T12:00:00Z")
      end
    end
  end
end
