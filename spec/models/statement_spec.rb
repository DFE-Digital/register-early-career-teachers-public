describe Statement do
  describe "associations" do
    it { is_expected.to belong_to(:lead_provider_active_period) }
    it { is_expected.to have_many(:adjustments) }
    it { is_expected.to have_many(:items) }
  end

  describe "state transitions" do
    context "when transitioning from open to payable" do
      let(:statement) { build(:statement, :open) }

      it { expect { statement.mark_as_payable! }.to change(statement, :state).from("open").to("payable") }
    end

    context "when transitioning from payable to paid" do
      let(:statement) { build(:statement, :payable) }

      it { expect { statement.mark_as_paid! }.to change(statement, :state).from("payable").to("paid") }
    end

    context "when transitioning to an invalid state" do
      let(:statement) { build(:statement, :paid) }

      it { expect { statement.mark_as_payable! }.to raise_error(StateMachines::InvalidTransition) }
    end
  end
end
