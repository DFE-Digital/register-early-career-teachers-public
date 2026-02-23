RSpec.describe PaymentCalculator::Banded::Uplifts do
  let(:instance) do
    described_class.new(declarations:, uplift_fee_per_declaration:)
  end

  # Billable declarations
  let!(:billable_eligible_declaration) do
    FactoryBot.create(:declaration, :eligible, :started, sparsity_uplift: true)
  end
  let!(:billable_payable_declaration) do
    FactoryBot.create(:declaration, :payable, :started, pupil_premium_uplift: true)
  end
  let!(:billable_paid_declaration) do
    FactoryBot.create(:declaration, :paid, :started, sparsity_uplift: true)
  end

  # Refundable declarations
  let!(:refundable_awaiting_clawback_declaration) do
    FactoryBot.create(:declaration, :awaiting_clawback, :started, sparsity_uplift: true)
  end

  # Out-of-scope declarations
  let!(:eligible_declaration_without_uplift) do
    FactoryBot.create(
      :declaration,
      :eligible,
      :started,
      sparsity_uplift: false,
      pupil_premium_uplift: false
    )
  end
  let(:clawed_back_declaration_without_uplift) do
    FactoryBot.create(
      :declaration,
      :clawed_back,
      :started,
      sparsity_uplift: false,
      pupil_premium_uplift: false
    )
  end
  let!(:no_payment_declaration) do
    FactoryBot.create(:declaration, :no_payment, :started, sparsity_uplift: true)
  end

  let(:declarations) { Declaration.all }
  let(:uplift_fee_per_declaration) { 125 }

  describe "#billable_count" do
    subject(:billable_count) { instance.billable_count }

    it { is_expected.to eq(3) }
  end

  describe "#refundable_count" do
    subject(:refundable_count) { instance.refundable_count }

    it { is_expected.to eq(1) }
  end

  describe "#net_count" do
    subject(:net_count) { instance.net_count }

    it { is_expected.to eq(2) }
  end

  describe "#total_billable_amount" do
    subject(:total_billable_amount) { instance.total_billable_amount }

    it { is_expected.to eq(375) }
  end

  describe "#total_refundable_amount" do
    subject(:total_refundable_amount) { instance.total_refundable_amount }

    it { is_expected.to eq(125) }
  end

  describe "total_net_amount" do
    subject(:total_net_amount) { instance.total_net_amount }

    it { is_expected.to eq(250) }
  end
end
