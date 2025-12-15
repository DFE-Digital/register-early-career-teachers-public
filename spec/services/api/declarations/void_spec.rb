RSpec.describe API::Declarations::Void, type: :model do
  subject(:instance) do
    described_class.new(declaration_id: declaration.api_id, lead_provider_id:)
  end

  let(:lead_provider_id) { declaration.training_period.lead_provider.id }

  describe "validations" do
    context "when lead_provider_id is missing" do
      let(:declaration) { FactoryBot.create(:declaration, :payable) }
      let(:lead_provider_id) { nil }

      it { is_expected.to have_one_error_per_attribute }
      it { is_expected.to have_error(:lead_provider_id, "Enter a '#/lead_provider_id'.") }
    end

    context "when lead provider does not exist" do
      let(:declaration) { FactoryBot.create(:declaration, :payable) }
      let(:lead_provider_id) { 123_456_789 }

      it { is_expected.to have_one_error_per_attribute }
      it { is_expected.to have_error(:lead_provider_id, "The '#/lead_provider_id' you have entered is invalid.") }
    end

    context "when declaration is voided" do
      let(:declaration) { FactoryBot.create(:declaration, :voided) }

      it { is_expected.to have_one_error_per_attribute }
      it { is_expected.to have_error(:declaration_id, "The declaration has already been voided.") }
    end

    context "when declaration is paid" do
      let(:declaration) { FactoryBot.create(:declaration, :paid) }

      it { is_expected.to have_one_error_per_attribute }
      it { is_expected.to have_error(:declaration_id, "This declaration has been clawed-back, so you can only view it.") }
    end

    Declaration::VOIDABLE_PAYMENT_STATUSES.each do |status|
      context "when declaration is #{status}" do
        let(:declaration) { FactoryBot.create(:declaration, :"#{status}") }

        it { is_expected.to be_valid }
      end
    end
  end

  describe "#void" do
    subject(:void) { instance.void }

    let(:declaration) { FactoryBot.create(:declaration, :payable) }

    it "voids via the service" do
      void_service = instance_double(Declarations::Void)
      allow(Declarations::Void)
        .to receive(:new)
        .with(author: instance_of(Events::LeadProviderAPIAuthor), declaration:)
        .and_return(void_service)

      expect(void_service).to receive(:void).once

      void
    end
  end
end
