RSpec.describe PaymentCalculator::Banded::DeclarationTypeOutput do
  subject(:instance) { described_class.new(band_allocation:) }

  let(:band_allocation) do
    PaymentCalculator::Banded::BandAllocation.new(band:, declaration_type:)
  end
  let(:band) do
    FactoryBot.build_stubbed(
      :contract_banded_fee_structure_band,
      fee_per_declaration: 150,
      output_fee_ratio: 0.5
    )
  end
  let(:declaration_type) { "started" }

  it { is_expected.to delegate_method(:declaration_type).to(:band_allocation) }

  describe "#output_fee_per_declaration" do
    subject(:output_fee_per_declaration) { instance.output_fee_per_declaration }

    it { is_expected.to eq(15) }

    context "when `declaration_type` is not supported" do
      let(:declaration_type) { "unsupported" }

      it "raises an error" do
        expect { output_fee_per_declaration }
          .to raise_error(PaymentCalculator::Banded::DeclarationTypeOutput::DeclarationTypeNotSupportedError)
          .with_message("No fee proportion defined for declaration type: unsupported")
      end
    end
  end

  describe "#total_billable_amount" do
    subject(:total_billable_amount) { instance.total_billable_amount }

    before { allow(band_allocation).to receive(:billable_count).and_return(5) }

    it { is_expected.to eq(75) }
  end

  describe "#total_refundable_amount" do
    subject(:total_refundable_amount) { instance.total_refundable_amount }

    before { allow(band_allocation).to receive(:refundable_count).and_return(3) }

    it { is_expected.to eq(45) }
  end

  describe "#total_net_amount" do
    subject(:total_net_amount) { instance.total_net_amount }

    before do
      allow(band_allocation).to receive_messages(billable_count: 5, refundable_count: 3)
    end

    it { is_expected.to eq(30) }
  end
end
