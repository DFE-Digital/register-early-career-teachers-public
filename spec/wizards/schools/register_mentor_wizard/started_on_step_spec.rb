RSpec.describe Schools::RegisterMentorWizard::StartedOnStep do
  subject(:step) { described_class.new(wizard:, started_on:) }

  let(:wizard) do
    instance_double(
      Schools::RegisterMentorWizard::Wizard,
      mentor:
    )
  end

  let(:mentor) do
    double(
      'Schools::RegisterMentorWizard::Mentor',
      mentoring_at_new_school_only: mentoring_only,
      became_ineligible_for_funding?: ineligible,
      provider_led_ect?: provider_led
    )
  end

  let(:mentoring_only) { 'no' }
  let(:ineligible) { false }
  let(:provider_led) { true }
  let(:started_on) { { 'day' => '10', 'month' => '9', 'year' => '2025' } }

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
