describe Statement::Item do
  describe "associations" do
    it { is_expected.to belong_to(:statement) }

    describe "state transitions" do
      context "when transitioning from eligible to payable" do
        let(:item) { build(:statement_item, :eligible) }

        it { expect { item.mark_as_payable! }.to change(item, :state).from("eligible").to("payable") }
      end

      context "when transitioning from payable to paid" do
        let(:item) { build(:statement_item, :payable) }

        it { expect { item.mark_as_paid! }.to change(item, :state).from("payable").to("paid") }
      end

      context "when transitioning from eligible to voided" do
        let(:item) { build(:statement_item, :eligible) }

        it { expect { item.mark_as_voided! }.to change(item, :state).from("eligible").to("voided") }
      end

      context "when transitioning from payable to voided" do
        let(:item) { build(:statement_item, :payable) }

        it { expect { item.mark_as_voided! }.to change(item, :state).from("payable").to("voided") }
      end

      context "when transitioning from paid to awaiting_clawback" do
        let(:item) { build(:statement_item, :paid) }

        it { expect { item.mark_as_awaiting_clawback! }.to change(item, :state).from("paid").to("awaiting_clawback") }
      end

      context "when transitioning from awaiting_clawback to clawed_back" do
        let(:item) { build(:statement_item, :awaiting_clawback) }

        it { expect { item.mark_as_clawed_back! }.to change(item, :state).from("awaiting_clawback").to("clawed_back") }
      end

      context "when transitioning from eligible to ineligible" do
        let(:item) { build(:statement_item, :eligible) }

        it { expect { item.mark_as_ineligible! }.to change(item, :state).from("eligible").to("ineligible") }
      end

      context "when transitioning from payable to eligible" do
        let(:item) { build(:statement_item, :payable) }

        it { expect { item.revert_to_eligible! }.to change(item, :state).from("payable").to("eligible") }
      end

      context "when transitioning to an invalid state" do
        let(:item) { build(:statement_item, :awaiting_clawback) }

        it { expect { item.mark_as_paid! }.to raise_error(StateMachines::InvalidTransition) }
      end
    end
  end
end
