RSpec.describe Declarations::Actions::MarkDeclarationsEligible do
  describe ".mark" do
    subject(:mark) { described_class.new(declarations:, author:).mark }

    let(:author) { Events::SystemAuthor.new }
    let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
    let(:training_period) { FactoryBot.create(:training_period, :with_active_lead_provider, active_lead_provider:) }
    let!(:no_payment_declaration) { FactoryBot.create(:declaration, :no_payment, declaration_type: :"retained-1", training_period:) }
    let!(:another_no_payment_declaration) { FactoryBot.create(:declaration, :no_payment, declaration_type: :"extended-1", training_period:) }
    let(:declarations) { [no_payment_declaration, another_no_payment_declaration] }

    let!(:next_output_fee_statement) do
      FactoryBot.create(
        :statement,
        :open,
        :output_fee,
        active_lead_provider:,
        deadline_date: Time.zone.today
      )
    end
    let!(:later_output_fee_statement) do
      FactoryBot.create(
        :statement,
        :open,
        :output_fee,
        active_lead_provider:,
        deadline_date: 1.day.from_now
      )
    end
    let!(:past_output_fee_statement) do
      FactoryBot.create(
        :statement,
        :open,
        :output_fee,
        active_lead_provider:,
        deadline_date: 1.day.ago
      )
    end
    let!(:service_fee_statement) do
      FactoryBot.create(
        :statement,
        :open,
        :service_fee,
        active_lead_provider:,
        deadline_date: Time.zone.today
      )
    end

    it "marks declarations as eligible" do
      expect { mark }
        .to change { no_payment_declaration.reload.payment_status }
        .from("no_payment")
        .to("eligible")
        .and change { another_no_payment_declaration.reload.payment_status }
        .from("no_payment")
        .to("eligible")
    end

    it "assigns the next output fee statement correctly" do
      mark

      expect(no_payment_declaration.reload.payment_statement).to eq(next_output_fee_statement)
      expect(another_no_payment_declaration.reload.payment_statement).to eq(next_output_fee_statement)
    end

    it "records an event for each successful declaration" do
      declarations.each do |declaration|
        expect(Events::Record)
        .to receive(:record_teacher_declaration_eligible!)
          .with(
            author:,
            teacher: declaration.training_period.teacher,
            training_period: declaration.training_period,
            declaration:
          )
      end

      mark
    end

    context "when there's a missing payment statement" do
      let!(:another_no_payment_declaration) { FactoryBot.create(:declaration, :no_payment, declaration_type: :"extended-1") }

      it "raises a `MissingPaymentStatementError`" do
        expect { mark }
        .to raise_error(Declarations::Actions::MarkDeclarationsEligible::MissingPaymentStatementError)
        .with_message(/Payment statement not found for declaration #{another_no_payment_declaration.id}/)
      end

      it "rolls back all updates" do
        expect { mark }
        .to raise_error(Declarations::Actions::MarkDeclarationsEligible::MissingPaymentStatementError)
        .and(not_change { no_payment_declaration.reload.payment_status })
        .and(not_change { no_payment_declaration.payment_statement })
        .and(not_change { another_no_payment_declaration.reload.payment_status })
        .and(not_change { another_no_payment_declaration.payment_statement })
      end
    end

    context "when a declaration is in a payment status that cannot transition to eligible" do
      let!(:already_eligible_declaration) { FactoryBot.create(:declaration, :eligible, declaration_type: :completed, training_period:) }

      let(:declarations) { [already_eligible_declaration] }

      it "raises `StateMachines::InvalidTransition` error" do
        expect { mark }.to raise_error(StateMachines::InvalidTransition)
      end

      it "does not record an event for it" do
        expect(Events::Record).not_to receive(:record_teacher_declaration_eligible!)

        expect { mark }.to raise_error(StateMachines::InvalidTransition)
      end
    end
  end
end
