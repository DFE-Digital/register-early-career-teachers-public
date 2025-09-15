describe API::SchoolPartnershipSerializer, type: :serializer do
  subject(:response) do
    JSON.parse(described_class.render(partnership))
  end

  let!(:partnership) { FactoryBot.create(:school_partnership) }
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
      expect(attributes["urn"]).to eq(school.urn.to_s)
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

    describe "participants_currently_training" do
      subject { attributes["participants_currently_training"] }

      context "when there are no `participants_currently_training`" do
        it { is_expected.to eq(0) }
      end

      context "when there are `participants_currently_training`" do
        before { FactoryBot.create_list(:training_period, 3, :ongoing, school_partnership: partnership) }

        it { is_expected.to eq(3) }
      end
    end

    it "serializes `created_at`" do
      partnership.created_at = Time.utc(2023, 7, 1, 12, 0, 0)

      expect(attributes["created_at"]).to eq(partnership.created_at.utc.rfc3339)
    end

    it "serializes `api_updated_at`" do
      partnership.api_updated_at = Time.utc(2023, 7, 2, 12, 0, 0)

      expect(attributes["updated_at"]).to eq(partnership.api_updated_at.utc.rfc3339)
    end
  end
end
