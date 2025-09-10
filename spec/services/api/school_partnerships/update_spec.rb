RSpec.describe API::SchoolPartnerships::Update, type: :model do
  let(:service) do
    described_class.new(
      school_partnership_id:,
      delivery_partner_api_id:
    )
  end

  let!(:school_partnership) { FactoryBot.create(:school_partnership) }
  let(:school_partnership_id) { school_partnership.id }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: school_partnership.active_lead_provider) }
  let(:delivery_partner_api_id) { lead_provider_delivery_partnership.delivery_partner.api_id }

  describe "validations" do
    subject { service }

    it { is_expected.to be_valid }

    it { is_expected.to validate_presence_of(:school_partnership_id).with_message("Enter a '#/school_partnership_id'.") }
    it { is_expected.to validate_presence_of(:delivery_partner_api_id).with_message("Enter a '#/delivery_partner_api_id'.") }

    context "when the delivery partner does not exist" do
      let(:delivery_partner_api_id) { SecureRandom.uuid }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:delivery_partner_api_id]).to include("The '#/delivery_partner_api_id' you have entered is invalid. Check delivery partner details and try again.")
      end
    end

    context "when the school partnership does not exist" do
      let(:school_partnership_id) { -1 }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:school_partnership_id]).to include("The '#/school_partnership_id' you have entered is invalid. Check partnership details and try again.")
      end
    end

    context "when the lead provider delivery partnership does not exist" do
      let(:delivery_partner_api_id) { FactoryBot.create(:delivery_partner).api_id }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:delivery_partner_api_id]).to include("The entered delivery partner is not recognised to be working in partnership with you for the given contract period. Contact the DfE for more information.")
      end
    end

    context "when the change in delivery partner would result in a duplicate school partnership" do
      before { FactoryBot.create(:school_partnership, school: school_partnership.school, lead_provider_delivery_partnership:) }

      it "is invalid" do
        expect(service).to be_invalid
        expect(service.errors[:delivery_partner_api_id]).to include("We are unable to process this request. You are already confirmed to be in partnership with the entered delivery partner. Contact the DfE for support.")
      end
    end
  end

  describe "#update" do
    subject(:update_school_partnership) { service.update }

    it "updates a school partnership via update service" do
      school_partnership_service = double("SchoolPartnerships::Update")
      allow(SchoolPartnerships::Update).to receive(:new).with(school_partnership:, lead_provider_delivery_partnership:).and_return(school_partnership_service)
      allow(school_partnership_service).to receive(:update).once

      update_school_partnership

      expect(school_partnership_service).to have_received(:update).once
    end

    context "when invalid" do
      let(:delivery_partner_api_id) { SecureRandom.uuid }

      it { is_expected.to be(false) }
      it { expect { update_school_partnership }.not_to(change { school_partnership.reload.attributes }) }
    end
  end
end
