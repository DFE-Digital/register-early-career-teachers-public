describe SchoolSerializer, type: :serializer do
  subject(:response) { JSON.parse(described_class.render(school, contract_period_id:)) }

  let(:school) { FactoryBot.create(:school, urn: "123456") }
  let(:school_partnership) { FactoryBot.create(:school_partnership, school:) }
  let(:contract_period_id) { school_partnership.contract_period.id }
  let(:ect_at_school_period) do
    FactoryBot.create(:ect_at_school_period,
                      :active,
                      :provider_led,
                      school:,
                      started_on: '2021-01-01')
  end
  let!(:training_period) do
    FactoryBot.create(:training_period,
                      ect_at_school_period:,
                      school_partnership:,
                      started_on: '2022-01-01',
                      finished_on: '2022-06-01')
  end

  describe "core attributes" do
    it "serializes `id`" do
      expect(response["id"]).to eq(school.api_id)
    end

    it "serializes `type`" do
      expect(response["type"]).to eq("school")
    end
  end

  describe "nested attributes" do
    subject(:attributes) { response["attributes"] }

    it "serializes `name`" do
      expect(attributes["name"]).to eq(school.name)
    end

    it "serializes `urn`" do
      expect(attributes["urn"]).to eq("123456")
    end

    it "serializes `cohort`" do
      expect(attributes["cohort"]).to eq(contract_period_id.to_s)
    end

    it "serializes `in_partnership`" do
      expect(attributes["in_partnership"]).to be(true)
    end

    it "serializes `induction_programme_choice`" do
      expect(attributes["induction_programme_choice"]).to eq("provider_led")
    end

    describe "timestamp serialization" do
      it "serializes `created_at`" do
        school.created_at = Time.utc(2023, 7, 1, 12, 0, 0)

        expect(attributes["created_at"]).to eq("2023-07-01T12:00:00Z")
      end

      it "serializes `updated_at`" do
        school.updated_at = Time.utc(2023, 7, 1, 12, 0, 0)

        expect(attributes["updated_at"]).to eq("2023-07-01T12:00:00Z")
      end
    end
  end
end
