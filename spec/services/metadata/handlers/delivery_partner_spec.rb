RSpec.describe Metadata::Handlers::DeliveryPartner do
  let(:instance) { described_class.new(delivery_partner) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let!(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner:, active_lead_provider:) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }
  let(:contract_period) { FactoryBot.create(:contract_period, year: 2021) }
  let(:contract_period_years) { [contract_period.year] }
  let(:lead_provider) { active_lead_provider.lead_provider }

  include_context "supports refreshing all metadata", :delivery_partner, DeliveryPartner do
    let(:object) { delivery_partner }
  end

  describe ".destroy_all_metadata!" do
    subject(:destroy_all_metadata) { described_class.destroy_all_metadata! }

    it "destroys all metadata for the delivery partner" do
      expect { destroy_all_metadata }.to change(Metadata::DeliveryPartnerLeadProvider, :count).from(1).to(0)
    end
  end

  describe "#refresh_metadata!" do
    subject(:refresh_metadata) { instance.refresh_metadata! }

    describe "DeliveryPartnerLeadProvider" do
      before { Metadata::DeliveryPartnerLeadProvider.destroy_all }

      include_context "supports tracking metadata upsert changes", Metadata::DeliveryPartnerLeadProvider do
        let(:handler) { instance }

        def perform_refresh_metadata
          refresh_metadata
        end
      end

      it "creates metadata for the delivery partner and lead provider" do
        expect { refresh_metadata }.to change(Metadata::DeliveryPartnerLeadProvider, :count).by(1)

        created_metadata = Metadata::DeliveryPartnerLeadProvider.last

        expect(created_metadata).to have_attributes(
          delivery_partner:,
          lead_provider:,
          contract_period_years:
        )
      end

      it "creates metadata for all combinations of the delivery partner and lead providers" do
        FactoryBot.create_list(:lead_provider, 2)

        expect { refresh_metadata }.to change(Metadata::DeliveryPartnerLeadProvider, :count).by(LeadProvider.count)
      end

      context "when metadata already exists for a delivery partner and lead provider" do
        let!(:metadata) { FactoryBot.create(:delivery_partner_lead_provider_metadata, delivery_partner:, lead_provider:, contract_period_years:) }

        it "does not create metadata" do
          expect { refresh_metadata }.not_to change(Metadata::DeliveryPartnerLeadProvider, :count)
        end

        it "updates the metadata when the partnership changes" do
          changed_contract_period = FactoryBot.create(:contract_period, year: 2022)

          Metadata::DeliveryPartnerLeadProvider.bypass_update_restrictions { metadata.update!(contract_period_years: [changed_contract_period.year]) }

          expect { refresh_metadata }.to change { metadata.reload.contract_period_years }.from([changed_contract_period.year]).to(contract_period_years)
        end

        it "does not update the metadata if no changes are made" do
          expect { refresh_metadata }.not_to(change { metadata.reload.attributes })
        end
      end
    end
  end
end
