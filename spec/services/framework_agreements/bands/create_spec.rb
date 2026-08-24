describe FrameworkAgreements::Bands::Create do
  subject(:service) { described_class.new(author:, framework_agreement:, capacity:) }

  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:framework_agreement) { FactoryBot.create(:framework_agreement, contract_period:) }
  let(:user) { FactoryBot.create(:user, :admin) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:capacity) { 750 }

  before do
    allow(Events::Record).to receive(:record_framework_agreement_band_added_event!)
  end

  context "with a valid capacity" do
    it "creates the band and records the created event" do
      result = nil
      expect { result = service.create! }.to change(FrameworkAgreement::Band, :count).by(1)
      expect(result).to have_attributes(framework_agreement:, capacity:)
      expect(Events::Record).to have_received(:record_framework_agreement_band_added_event!).with(author:, band: result)
    end
  end

  context "with an invalid capacity" do
    let(:capacity) { nil }

    it "raises an error and does not save or record an event" do
      expect { service.create! }.to raise_error(ActiveRecord::RecordInvalid)
      expect(Events::Record).not_to have_received(:record_framework_agreement_band_added_event!)
    end
  end
end
