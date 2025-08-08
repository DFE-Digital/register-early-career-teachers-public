describe PartnershipSerializer, type: :serializer do
  subject(:response) do
    JSON.parse(described_class.render(partnership))
  end

  let(:partnership) { FactoryBot.create(:school_partnership) }
  let(:school) { partnership.school }
  let(:delivery_partner) { partnership.delivery_partner }
  let(:contract_period) { partnership.contract_period }

  describe "core attributes" do
    it "serializes `id`" do
      expect(response["id"]).to eq(partnership.api_id)
    end

    it "serializes `type`" do
      expect(response["type"]).to eq("partnership")
    end
  end

  describe "nested attributes" do
    subject(:attributes) { response["attributes"] }

    it "serializes `cohort`" do
      expect(attributes["cohort"]).to eq(contract_period.year.to_s)
    end

    it "serializes `urn`" do
      expect(attributes["urn"]).to eq(school.urn)
    end

    it "serializes `school_id`" do
      expect(attributes["school_id"]).to eq(school.api_id)
    end

    it "serializes `delivery_partner_id`" do
      expect(attributes["delivery_partner_id"]).to eq(delivery_partner.api_id)
    end

    it "serializes `delivery_partner_name`" do
      expect(attributes["delivery_partner_name"]).to eq(delivery_partner.name)
    end

    it "serializes `induction_tutor_name`" do
      expect(attributes["induction_tutor_name"]).to eq(school.induction_tutor_name)
    end

    it "serializes `induction_tutor_email`" do
      expect(attributes["induction_tutor_email"]).to eq(school.induction_tutor_email)
    end

    it "serializes `created_at`" do
      expect(attributes["created_at"]).to eq(partnership.created_at.utc.rfc3339)
    end

    it "serializes `updated_at`" do
      # TODO: Replace with `api_updated_at` when the field is available
      expect(attributes["updated_at"]).to eq(partnership.updated_at.utc.rfc3339)
      # partnership.update!(api_updated_at: 3.days.ago)
      # expect(attributes["updated_at"]).to eq(partnership.api_updated_at.utc.rfc3339)
    end
  end
end
