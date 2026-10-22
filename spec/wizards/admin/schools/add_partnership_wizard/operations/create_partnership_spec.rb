RSpec.describe Admin::Schools::AddPartnershipWizard::Operations::CreatePartnership do
  subject(:operation) { described_class.new(step:) }

  let(:author) { instance_double(User) }
  let(:school) { instance_double(School) }
  let(:partnership) { instance_double(LeadProviderDeliveryPartnership) }

  let(:wizard) do
    instance_double(
      Admin::Schools::AddPartnershipWizard::Wizard,
      author:,
      school:,
      lead_provider_delivery_partnership: partnership
    )
  end

  let(:step) do
    instance_double(
      Admin::Schools::AddPartnershipWizard::CheckAnswersStep,
      wizard:
    )
  end

  let(:service) { instance_double(SchoolPartnerships::Create) }

  describe "#execute" do
    before do
      allow(SchoolPartnerships::Create).to receive(:new).and_return(service)
      allow(service).to receive(:create)
    end

    it "creates the partnership and returns success" do
      expect(operation.execute).to eq(success: true)

      expect(SchoolPartnerships::Create).to have_received(:new).with(
        author:,
        school:,
        lead_provider_delivery_partnership: partnership
      )

      expect(service).to have_received(:create)
    end
  end
end
