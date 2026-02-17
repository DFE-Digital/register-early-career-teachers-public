RSpec.describe API::Declarations::Clawback, type: :model do
  subject(:instance) do
    described_class.new(declaration_api_id: declaration.api_id, lead_provider_id:)
  end

  let(:lead_provider_id) { declaration.training_period.lead_provider.id }

  before { ensure_active_lead_providers_are_consistent }

  context "when lead_provider_id is missing" do
    let(:declaration) { FactoryBot.create(:declaration, :paid) }
    let(:lead_provider_id) { nil }

    it { is_expected.to have_one_error_per_attribute }
    it { is_expected.to have_error(:lead_provider_id, "Enter a '#/lead_provider_id'.") }
  end

  context "when lead provider does not exist" do
    let(:declaration) { FactoryBot.create(:declaration, :paid) }
    let(:lead_provider_id) { 123_456_789 }

    it { is_expected.to have_one_error_per_attribute }
    it { is_expected.to have_error(:lead_provider_id, "The '#/lead_provider_id' you have entered is invalid.") }
  end

  context "when declaration is awaiting clawback" do
    let(:declaration) { FactoryBot.create(:declaration, :awaiting_clawback) }

    it { is_expected.to have_one_error_per_attribute }
    it { is_expected.to have_error(:declaration_api_id, "The declaration will or has been refunded") }
  end

  context "when declaration has been clawed back" do
    let(:declaration) { FactoryBot.create(:declaration, :clawed_back) }

    it { is_expected.to have_one_error_per_attribute }
    it { is_expected.to have_error(:declaration_api_id, "The declaration will or has been refunded") }
  end

  context "when the declaration's payment statement has no output fee" do
    let(:declaration) { FactoryBot.create(:declaration, :paid) }

    before { declaration.payment_statement.update!(fee_type: :service) }

    it { is_expected.to have_one_error_per_attribute }

    it "has the correct error message" do
      contract_period_year = declaration.training_period.contract_period.year
      error_message = <<~TXT.squish
        You cannot submit or void declarations for the #{contract_period_year}
        contract period. The funding contract for this contract period has
        ended. Get in touch if you need to discuss this with us
      TXT
      expect(instance).to have_error(:declaration_api_id, error_message)
    end
  end

  context "when the declaration's payment statement deadline date is in the past" do
    let(:declaration) { FactoryBot.create(:declaration, :paid) }

    before { declaration.payment_statement.update!(deadline_date: Date.yesterday) }

    it { is_expected.to have_one_error_per_attribute }

    it "has the correct error message" do
      contract_period_year = declaration.training_period.contract_period.year
      error_message = <<~TXT.squish
        You cannot submit or void declarations for the #{contract_period_year}
        contract period. The funding contract for this contract period has
        ended. Get in touch if you need to discuss this with us
      TXT
      expect(instance).to have_error(:declaration_api_id, error_message)
    end
  end

  context "when declaration has not been refunded and output fee is available" do
    let(:declaration) { FactoryBot.create(:declaration, :paid) }

    it { is_expected.to be_valid }
  end

  describe "#clawback" do
    subject(:clawback) { instance.clawback }

    let(:declaration) { FactoryBot.create(:declaration, :paid) }

    it "claws back via the service" do
      clawback_service = instance_double(Declarations::Clawback)
      allow(Declarations::Clawback)
        .to receive(:new)
        .with(
          author: instance_of(Events::LeadProviderAPIAuthor),
          declaration:,
          next_available_output_fee_statement: declaration.payment_statement
        )
        .and_return(clawback_service)

      expect(clawback_service).to receive(:clawback).once

      clawback
    end
  end

private

  def ensure_active_lead_providers_are_consistent
    # Using update_all bypasses the readonly check on that attribute.
    active_lead_provider_id = declaration.training_period.active_lead_provider.id
    Contract.where(id: declaration.payment_statement.contract).update_all(active_lead_provider_id:)
  end
end
