require_relative "./shared_examples/started_on_step"

RSpec.describe Schools::RegisterMentorWizard::ChangeStartedOnStep do
  subject(:step) { described_class.new(wizard:, started_on:) }

  let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :started_on, store:) }
  let(:store) do
    FactoryBot.build(:session_repository,
                     mentoring_at_new_school_only: "no")
  end

  let(:started_on) { { "day" => "10", "month" => "9", "year" => "2025" } }

  it_behaves_like "a started on step", current_step: :started_on

  describe "#next_step" do
    context "when contract period is open" do
      let!(:contract_period) { FactoryBot.create(:contract_period, year: 2025, enabled: true) }

      it { expect(step.next_step).to eq(:check_answers) }
    end
  end

  describe "#previous_step" do
    it { expect(step.previous_step).to eq(:check_answers) }
  end
end
