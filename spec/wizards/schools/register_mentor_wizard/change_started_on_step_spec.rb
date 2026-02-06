require_relative "./shared_examples/started_on_step"

RSpec.describe Schools::RegisterMentorWizard::ChangeStartedOnStep do
  subject(:step) { described_class.new(wizard:, started_on:) }

  let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :started_on, store:) }
  let(:store) do
    FactoryBot.build(:session_repository,
                     mentoring_at_new_school_only: mentoring_only)
  end

  let(:mentoring_only) { "no" }
  let(:ineligible) { false }
  let(:provider_led) { true }
  let(:started_on) { { "day" => "10", "month" => "9", "year" => "2025" } }
  let(:previous_training_period) { FactoryBot.build(:training_period) }
  let(:contract_period) { FactoryBot.create(:contract_period, year: 2025, enabled: true) }
  let(:contract_period_enabled?) { contract_period.enabled }
  let(:currently_mentor_at_another_school) { false }

  it_behaves_like "a started on step", current_step: :started_on

  describe "#next_step" do
    it { expect(step.previous_step).to eq(:check_answers) }
  end

  describe "#previous_step" do
    it { expect(step.previous_step).to eq(:check_answers) }
  end
end
