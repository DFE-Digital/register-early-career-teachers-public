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

  describe "#previous_step" do
    it { expect(step.previous_step).to eq(:check_answers) }
  end
end
