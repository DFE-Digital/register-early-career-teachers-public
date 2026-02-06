RSpec.describe Schools::RegisterMentorWizard::CannotRegisterMentorYetStep do
  subject(:step) { described_class.new(wizard:) }

  let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :cannot_register_mentor_yet, store:) }
  let(:store) { FactoryBot.build(:session_repository) }

  describe "#previous_step" do
    context "when revised_start_date_in_closed_contract_period is true" do
      before do
        store.revised_start_date_in_closed_contract_period = true
        store.back_to = "check_answers"
      end

      it "resets revised_start_date_in_closed_contract_period and back_to, and returns :check_answers" do
        expect(step.previous_step).to eq(:check_answers)
        expect(store.revised_start_date_in_closed_contract_period).to be_nil
        expect(store.back_to).to be_nil
      end
    end

    context "when revised_start_date_in_closed_contract_period is not true" do
      it "returns :started_on" do
        expect(step.previous_step).to eq(:started_on)
      end
    end
  end
end
