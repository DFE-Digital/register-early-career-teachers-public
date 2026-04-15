require_relative "./shared_examples/started_on_step"

RSpec.describe Schools::RegisterMentorWizard::ChangeStartedOnStep do
  subject(:step) { described_class.new(wizard:, started_on: started_on_params) }

  let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :started_on, store:) }
  let(:store) do
    FactoryBot.build(:session_repository, mentoring_at_new_school_only: "no")
  end

  let(:started_on) { Date.new(2025, 9, 10) }
  let(:started_on_params) do
    {
      "day" => started_on.day.to_s,
      "month" => started_on.month.to_s,
      "year" => started_on.year.to_s
    }
  end

  let!(:contract_period) do
    FactoryBot.create(:contract_period, :current, enabled: contract_period_enabled)
  end
  let(:contract_period_enabled) { true }

  it_behaves_like "a started on step", current_step: :started_on

  describe "#next_step" do
    subject(:next_step) { step.next_step }

    context "when registrations are closed for the contract period" do
      let(:started_on) { 1.day.from_now }
      let(:contract_period_enabled) { false }

      it { is_expected.to eq(:cannot_register_mentor_yet) }
    end

    context "when registrations are open for the contract period" do
      let(:started_on) { 1.day.from_now }
      let(:contract_period_enabled) { true }

      it { is_expected.to eq(:check_answers) }
    end
  end

  describe "#previous_step" do
    subject(:previous_step) { step.previous_step }

    it { is_expected.to eq(:check_answers) }
  end
end
