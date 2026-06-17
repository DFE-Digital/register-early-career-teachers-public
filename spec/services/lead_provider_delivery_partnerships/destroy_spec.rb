describe LeadProviderDeliveryPartnerships::Destroy do
  subject(:service) { described_class.new(author:, lead_provider_delivery_partnership:) }

  let(:user) { FactoryBot.create(:user, :admin) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let!(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership) }

  before do
    allow(Events::Record).to receive(:record_lead_provider_delivery_partnership_removed_event!)
  end

  context "when the partnership has no school partnerships" do
    it "destroys the partnership and records a removed event" do
      result = nil
      expect { result = service.call }.to change(LeadProviderDeliveryPartnership, :count).by(-1)

      expect(result).to be(true)
      expect(Events::Record).to have_received(:record_lead_provider_delivery_partnership_removed_event!).with(
        author:,
        delivery_partner: lead_provider_delivery_partnership.delivery_partner,
        lead_provider: lead_provider_delivery_partnership.lead_provider,
        contract_period: lead_provider_delivery_partnership.contract_period,
        lead_provider_delivery_partnership:
      )
    end
  end

  context "when the partnership has school partnerships" do
    before { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:) }

    it "raises DeletionError and does not destroy the partnership or record an event" do
      expect { service.call }.to raise_error(
        LeadProviderDeliveryPartnerships::Destroy::DeletionError,
        "Cannot remove a delivery partner with school partnerships"
      )

      expect(LeadProviderDeliveryPartnership.exists?(lead_provider_delivery_partnership.id)).to be(true)
      expect(Events::Record).not_to have_received(:record_lead_provider_delivery_partnership_removed_event!)
    end
  end
end
