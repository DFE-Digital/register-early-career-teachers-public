RSpec.describe API::Declarations::Void, type: :model do
  subject(:instance) do
    described_class.new(declaration_id: declaration.api_id, voided_by_user_id:)
  end

  let(:voided_by_user_id) { nil }

  before { ensure_active_lead_providers_are_consistent }

  describe "validations" do
    context "when clawing back" do
      context "when declaration is awaiting clawback" do
        let(:declaration) { FactoryBot.create(:declaration, :awaiting_clawback) }

        it { is_expected.to have_one_error_per_attribute }
        it { is_expected.to have_error(:declaration_id, "The declaration has already been refunded") }
      end

      context "when declaration has been clawed back" do
        let(:declaration) { FactoryBot.create(:declaration, :clawed_back) }

        it { is_expected.to have_one_error_per_attribute }
        it { is_expected.to have_error(:declaration_id, "The declaration has already been refunded") }
      end

      context "when the declaration's payment statement has no output fee" do
        let(:declaration) { FactoryBot.create(:declaration, :paid) }

        before { declaration.payment_statement.update!(fee_type: :service) }

        it { is_expected.to have_one_error_per_attribute }
        it { is_expected.to have_error(:declaration_id, "The output fee statement is not available") }
      end

      context "when the declaration's payment statement deadline date is in the past" do
        let(:declaration) { FactoryBot.create(:declaration, :paid) }

        before { declaration.payment_statement.update!(deadline_date: Date.yesterday) }

        it { is_expected.to have_one_error_per_attribute }
        it { is_expected.to have_error(:declaration_id, "The output fee statement is not available") }
      end

      context "when declaration has not been refunded and output fee is available" do
        let(:declaration) { FactoryBot.create(:declaration, :paid) }

        it { is_expected.to be_valid }
      end
    end

    context "when voiding" do
      context "when declaration is already voided" do
        let(:declaration) { FactoryBot.create(:declaration, :voided) }

        it { is_expected.to have_one_error_per_attribute }
        it { is_expected.to have_error(:declaration_id, "The declaration has already been voided") }
      end

      context "when declaration has not been voided" do
        let(:declaration) { FactoryBot.create(:declaration, :payable) }

        it { is_expected.to be_valid }
      end
    end
  end

  describe "#clawback_or_void" do
    subject(:clawback_or_void) { instance.clawback_or_void }

    context "when clawing back" do
      let(:declaration) { FactoryBot.create(:declaration, :paid) }

      it "claws back via the service" do
        void_service = instance_double(Declarations::Void)
        allow(Declarations::Void)
          .to receive(:new)
          .and_return(void_service)

        expect(void_service).to receive(:clawback).once

        clawback_or_void
      end
    end

    context "when voiding" do
      let(:declaration) { FactoryBot.create(:declaration, :payable) }

      it "voids via the service" do
        void_service = instance_double(Declarations::Void)
        allow(Declarations::Void)
          .to receive(:new)
          .and_return(void_service)

        expect(void_service).to receive(:void).once

        clawback_or_void
      end
    end
  end

private

  def ensure_active_lead_providers_are_consistent
    active_lead_provider = declaration.training_period.active_lead_provider
    declaration.payment_statement.update!(active_lead_provider:)
  end
end
