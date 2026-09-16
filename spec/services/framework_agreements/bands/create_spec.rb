describe FrameworkAgreements::Bands::Create do
  subject(:service) { described_class.new(author:, framework_agreement:, capacity:) }

  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:framework_agreement) { FactoryBot.create(:framework_agreement, contract_period:) }
  let(:user) { FactoryBot.create(:user, :admin) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:capacity) { 750 }

  context "with a valid capacity" do
    it "creates the band and records the created event" do
      result = nil
      expect { result = service.create! }.to change(FrameworkAgreement::Band, :count).by(1)
      expect(result).to have_attributes(framework_agreement:, capacity:)
      expect(Event.where(event_type: "band_added").sole).to have_attributes(
        framework_agreement_id: framework_agreement.id,
        lead_provider_id: framework_agreement.lead_provider_id
      )
    end
  end

  context "with an invalid capacity" do
    let(:capacity) { nil }

    it "raises an error and does not save or record an event" do
      expect { service.create! }.to raise_error(ActiveRecord::RecordInvalid)
      expect(Event.where(event_type: "band_added")).to be_empty
    end
  end
end
