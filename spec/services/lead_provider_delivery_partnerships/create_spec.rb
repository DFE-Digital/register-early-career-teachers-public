describe LeadProviderDeliveryPartnerships::Create do
  subject(:service) { described_class.new(author:, framework_agreement:, params:) }

  let(:user) { FactoryBot.create(:user, :admin) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:framework_agreement) { FactoryBot.create(:framework_agreement) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:params) { { delivery_partner_id: delivery_partner.id } }

  before do
    allow(Events::Record).to receive(:record_lead_provider_delivery_partnership_added_event!)
  end

  context "with valid params" do
    it "creates the lead provider delivery partnership and records an added event" do
      result = nil
      expect { result = service.call }.to change(LeadProviderDeliveryPartnership, :count).by(1)

      expect(result).to be_persisted
      expect(result).to have_attributes(framework_agreement:, delivery_partner:)
      expect(Events::Record).to have_received(:record_lead_provider_delivery_partnership_added_event!).with(
        author:,
        delivery_partner:,
        lead_provider: framework_agreement.lead_provider,
        contract_period: framework_agreement.contract_period,
        lead_provider_delivery_partnership: result
      )
    end
  end

  context "with invalid params" do
    let(:params) { { delivery_partner_id: nil } }

    it "raises ActiveRecord::RecordInvalid and does not record an event" do
      expect { service.call }.to raise_error(ActiveRecord::RecordInvalid)
      expect(Events::Record).not_to have_received(:record_lead_provider_delivery_partnership_added_event!)
    end
  end
end
