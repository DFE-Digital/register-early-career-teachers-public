RSpec.describe DeliveryPartners::API::Query do
  shared_examples "preloaded associations" do
    it { expect(result.association(:lead_provider_metadata)).to be_loaded }

    context "when a lead_provider_id is specified" do
      let(:lead_provider_id) { lead_provider.id }

      before { FactoryBot.create(:lead_provider_delivery_partnership, lead_provider:, delivery_partner:) }

      it "only contains relevant metadata" do
        expect(result.lead_provider_metadata).to contain_exactly(lead_provider_metadata)
      end
    end
  end

  describe "preloading relationships" do
    let(:lead_provider_id) { :ignore }
    let(:instance) { described_class.new(lead_provider_id:) }

    let!(:delivery_partner) { FactoryBot.create(:delivery_partner) }
    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let!(:lead_provider_metadata) { FactoryBot.create(:delivery_partner_lead_provider_metadata, delivery_partner:, lead_provider:) }

    before do
      # Ensure other metadata exists.
      other_lead_provider = FactoryBot.create(:lead_provider)
      FactoryBot.create(:delivery_partner_lead_provider_metadata, delivery_partner:, lead_provider: other_lead_provider)
    end

    describe "#delivery_partners" do
      subject(:result) { instance.delivery_partners.first }

      include_context "preloaded associations"
    end

    describe "#delivery_partner_by_api_id" do
      subject(:result) { instance.delivery_partner_by_api_id(delivery_partner.api_id) }

      include_context "preloaded associations"
    end

    describe "#delivery_partner_by_id" do
      subject(:result) { instance.delivery_partner_by_id(delivery_partner.id) }

      include_context "preloaded associations"
    end
  end
end
