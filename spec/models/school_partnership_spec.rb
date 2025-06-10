describe SchoolPartnership do
  describe "associations" do
    it { is_expected.to belong_to(:registration_period).inverse_of(:school_partnerships) }
    it { is_expected.to belong_to(:lead_provider).inverse_of(:school_partnerships) }
    it { is_expected.to belong_to(:delivery_partner).inverse_of(:school_partnerships) }
    it { is_expected.to have_many(:events) }
  end

  describe "validations" do
    subject { FactoryBot.create(:school_partnership) }

    it { is_expected.to validate_presence_of(:registration_period_id) }
    it { is_expected.to validate_presence_of(:lead_provider_id) }
    it { is_expected.to validate_presence_of(:delivery_partner_id) }

    context "uniqueness of registration_period scoped to lead_provider_id and delivery_partner_id" do
      context "when the provider partnership matches the lead_provider_id, delivery_partner_id and registration_period values
               of an existing provider partnership" do
        subject { FactoryBot.build(:school_partnership, registration_period_id:, lead_provider_id:, delivery_partner_id:) }

        let!(:existing_partnership) { FactoryBot.create(:school_partnership) }
        let(:registration_period_id) { existing_partnership.registration_period_id }
        let(:lead_provider_id) { existing_partnership.lead_provider_id }
        let(:delivery_partner_id) { existing_partnership.delivery_partner_id }

        before do
          subject.valid?
        end

        it "add an error" do
          expect(subject.errors.messages).to include(registration_period_id: ["has already been added"])
        end
      end
    end
  end

  end
end
