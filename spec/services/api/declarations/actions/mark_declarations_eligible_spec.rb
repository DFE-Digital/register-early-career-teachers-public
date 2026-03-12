RSpec.describe Declarations::Actions::MarkDeclarationsEligible do
  describe ".mark" do
    subject(:mark) { described_class.new(declarations:, author:).mark }

    let(:author) { Events::SystemAuthor.new }
    let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
    let(:training_period) { FactoryBot.create(:training_period, :with_active_lead_provider, active_lead_provider:) }
    let(:declarations) { Declaration.where(id: [no_payment_declaration.id, already_eligible_declaration.id]) }
    let!(:no_payment_declaration) { FactoryBot.create(:declaration, :no_payment, training_period:) }
    let!(:already_eligible_declaration) { FactoryBot.create(:declaration, :eligible, declaration_type: :completed, training_period:) }

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

    it "marks only `no_payment` declarations eligible" do
      expect { mark }
        .to change { no_payment_declaration.reload.payment_status }
        .from("no_payment")
        .to("eligible")
        .and(not_change { already_eligible_declaration.reload.payment_status })
    end

    it "assigns the next output fee statement correctly" do
      mark

      expect(no_payment_declaration.reload.payment_statement).to eq(next_output_fee_statement)
    end

    it "records an event" do
      expect(Events::Record)
        .to receive(:record_teacher_declaration_marked_eligible!)
        .with(
          author:,
          teacher: no_payment_declaration.training_period.teacher,
          training_period: no_payment_declaration.training_period,
          declaration: no_payment_declaration
        )

      mark
    end

    context "when one of the declarations cannot be updated" do
      let!(:first_no_payment_declaration) { FactoryBot.create(:declaration, :no_payment, declaration_type: :"retained-1", training_period:) }
      let!(:second_no_payment_declaration) { FactoryBot.create(:declaration, :no_payment, declaration_type: :"extended-1") }
      let(:declarations) { Declaration.where(id: [first_no_payment_declaration.id, second_no_payment_declaration.id]) }

      it "rolls back all updates" do
        expect { mark }.to raise_error(ActiveRecord::RecordInvalid)

        expect(first_no_payment_declaration.reload.payment_status).to eq("no_payment")
        expect(first_no_payment_declaration.payment_statement).to be_nil
        expect(second_no_payment_declaration.reload.payment_status).to eq("no_payment")
        expect(second_no_payment_declaration.payment_statement).to be_nil
      end
    end
  end
end
