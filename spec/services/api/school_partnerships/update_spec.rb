RSpec.describe API::SchoolPartnerships::Update, type: :model do
  let(:service) do
    described_class.new(
      school_partnership:,
      delivery_partner_ecf_id:
    )
  end

  let(:school_partnership) { create(:school_partnership) }

  let(:delivery_partner) { create(:delivery_partner) }
  let(:delivery_partner_ecf_id) { delivery_partner.ecf_id }

  let!(:lead_provider_active_period) { school_partnership.lead_provider_active_period }
  let!(:lead_provider_delivery_partnership) { create(:lead_provider_delivery_partnership, lead_provider_active_period:, delivery_partner:) }

  describe "validations" do
    subject { service }

    it { is_expected.to be_valid }

    it { is_expected.to validate_presence_of(:school_partnership) }
    it { is_expected.to validate_presence_of(:delivery_partner_ecf_id) }

    context "when the delivery partner does not exist" do
      let(:delivery_partner_ecf_id) { SecureRandom.uuid }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:delivery_partner_ecf_id]).to include("Delivery partner does not exist")
      end
    end

    context "when a lead provider delivery partnership does not exist" do
      let(:lead_provider_delivery_partnership) { nil }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:delivery_partner_ecf_id]).to include("Lead provider and delivery partner do not have a partnership")
      end
    end

    context "when the school partnership already exists" do
      before { create(:school_partnership, school: school_partnership.school, lead_provider_delivery_partnership:) }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:school_ecf_id]).to include("School partnership already exists for the lead provider, delivery partner and registration year")
      end
    end
  end

  describe "#update" do
    subject(:update_school_partnership) { service.update }

    it "update the school partnership" do
      expect { update_school_partnership }.to change(school_partnership, :delivery_partner).to(delivery_partner)
    end

    context "when invalid" do
      let(:delivery_partner_ecf_id) { SecureRandom.uuid }

      it { is_expected.to be(false) }
      it { expect { update_school_partnership }.not_to change(school_partnership, :delivery_partner) }
    end
  end
end
