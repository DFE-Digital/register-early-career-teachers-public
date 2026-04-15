require_relative "./shared_examples/started_on_step"

RSpec.describe Schools::RegisterMentorWizard::StartedOnStep do
  subject(:step) { described_class.new(wizard:, started_on: started_on_params) }

  let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :started_on, store:) }
  let(:store) do
    FactoryBot.build(:session_repository, mentoring_at_new_school_only: mentoring_only)
  end

  let(:mentoring_only) { "no" }
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

    let(:ineligible) { false }
    let(:provider_led) { true }
    let(:previous_training_period) { FactoryBot.build(:training_period) }

    before do
      allow(wizard.mentor).to receive_messages(
        provider_led_ect?: provider_led,
        became_ineligible_for_funding?: ineligible,
        previous_training_period:
      )
    end

    context "when contract period is missing" do
      let!(:contract_period) { nil }

      context "when started_on is today" do
        let(:started_on) { Date.current }

        it { is_expected.not_to eq(:cannot_register_mentor_yet) }
      end

      context "when started_on is in the past" do
        let(:started_on) { 1.day.ago }

        it { is_expected.not_to eq(:cannot_register_mentor_yet) }
      end

      context "when started_on is in the future" do
        let(:started_on) { 1.day.from_now }

        it { is_expected.to eq(:cannot_register_mentor_yet) }
      end
    end

    context "when contract period is disabled" do
      let(:contract_period_enabled) { false }

      context "when started_on is today" do
        let(:started_on) { Date.current }

        it { is_expected.not_to eq(:cannot_register_mentor_yet) }
      end

      context "when started_on is in the past" do
        let(:started_on) { 1.day.ago }

        it { is_expected.not_to eq(:cannot_register_mentor_yet) }
      end

      context "when started_on is in the future" do
        let(:started_on) { 1.day.from_now }

        it { is_expected.to eq(:cannot_register_mentor_yet) }
      end
    end

    context "when contract period is enabled" do
      let(:contract_period_enabled) { true }

      context "when started_on is today" do
        let(:started_on) { Date.current }

        it { is_expected.not_to eq(:cannot_register_mentor_yet) }
      end

      context "when started_on is in the past" do
        let(:started_on) { 1.day.ago }

        it { is_expected.not_to eq(:cannot_register_mentor_yet) }
      end

      context "when started_on is in the future" do
        let(:started_on) { 1.day.from_now }

        it { is_expected.not_to eq(:cannot_register_mentor_yet) }
      end
    end

    context "when mentor is ineligible for funding" do
      let(:ineligible) { true }

      it { is_expected.to eq(:check_answers) }
    end

    context "when ECT is school-led" do
      let(:provider_led) { false }

      it { is_expected.to eq(:check_answers) }
    end

    context "when there is no previous training period" do
      let(:previous_training_period) { nil }

      it { is_expected.to eq(:programme_choices) }
    end

    context "when mentor is eligible, contract period is enabled, ECT is provider-led, and there is a previous training period" do
      it { is_expected.to eq(:previous_training_period_details) }
    end
  end

  describe "#previous_step" do
    subject(:previous_step) { step.previous_step }

    context "when mentoring_at_new_school_only is 'yes'" do
      let(:mentoring_only) { "yes" }

      it { is_expected.to eq(:mentoring_at_new_school_only) }
    end

    context "when mentoring_at_new_school_only is 'no'" do
      let(:mentoring_only) { "no" }

      it { is_expected.to eq(:email_address) }
    end
  end
end
