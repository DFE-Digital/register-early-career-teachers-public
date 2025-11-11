RSpec.describe Schools::RegisterMentorWizard::StartedOnStep do
  subject(:step) { described_class.new(wizard:, started_on:) }

  let(:wizard) do
    instance_double(
      Schools::RegisterMentorWizard::Wizard,
      mentor: registration_session
    )
  end

  let(:registration_session) do
    double(
      'Schools::RegisterMentorWizard::RegistrationSession',
      mentoring_at_new_school_only: mentoring_only,
      became_ineligible_for_funding?: ineligible,
      provider_led_ect?: provider_led,
      previous_training_period:
    )
  end

  let(:mentoring_only) { 'no' }
  let(:ineligible) { false }
  let(:provider_led) { true }
  let(:started_on) { { 'day' => '10', 'month' => '9', 'year' => '2025' } }
  let(:previous_training_period) { FactoryBot.build(:training_period) }

  describe '#next_step' do
    context 'when mentor is ineligible for funding' do
      let(:ineligible) { true }

      it { expect(step.next_step).to eq(:check_answers) }
    end

    context 'when ECT is school-led' do
      let(:provider_led) { false }

      it { expect(step.next_step).to eq(:check_answers) }
    end

    context 'when mentor is eligible and ECT is provider-led' do
      it { expect(step.next_step).to eq(:previous_training_period_details) }
    end

    context 'when there is no previous training period' do
      let(:previous_training_period) { nil }

      it { expect(step.next_step).to eq(:programme_choices) }
    end
  end

  describe '#previous_step' do
    context "when mentoring_at_new_school_only is 'yes'" do
      let(:mentoring_only) { 'yes' }

      it { expect(step.previous_step).to eq(:mentoring_at_new_school_only) }
    end

    context "when mentoring_at_new_school_only is 'no'" do
      it { expect(step.previous_step).to eq(:email_address) }
    end
  end
end
