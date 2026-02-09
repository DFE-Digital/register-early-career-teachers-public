require_relative "./shared_examples/started_on_step"

RSpec.describe Schools::RegisterMentorWizard::StartedOnStep do
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
    around do |example|
      travel_to(Date.new(2025, 1, 1)) { example.run }
    end

    before do
      allow(wizard.mentor).to receive_messages(provider_led_ect?: provider_led, became_ineligible_for_funding?: ineligible, previous_training_period:, contract_period_enabled?: contract_period_enabled?)
    end

    context "when mentor is ineligible for funding" do
      let(:ineligible) { true }

      it { expect(step.next_step).to eq(:check_answers) }
    end

    context "when ECT is school-led" do
      let(:provider_led) { false }

      it { expect(step.next_step).to eq(:check_answers) }
    end

    context "when the start date is in the past" do
      let(:contract_period) { FactoryBot.create(:contract_period, year: 2024) }
      let(:started_on) { { "day" => "10", "month" => "9", "year" => "2024" } }

      it { expect(step.next_step).to eq(:previous_training_period_details) }
    end

    context "when mentor is eligible, the contract period is open and ECT is provider-led" do
      it { expect(step.next_step).to eq(:previous_training_period_details) }
    end

    context "when there is no previous training period" do
      let(:previous_training_period) { nil }

      it { expect(step.next_step).to eq(:programme_choices) }
    end
  end

  describe "#previous_step" do
    context "when mentoring_at_new_school_only is 'yes'" do
      let(:mentoring_only) { "yes" }

      it { expect(step.previous_step).to eq(:mentoring_at_new_school_only) }
    end

    context "when mentoring_at_new_school_only is 'no'" do
      it { expect(step.previous_step).to eq(:email_address) }
    end
  end
end
