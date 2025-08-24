RSpec.describe Schools::RegisterMentorWizard::ProgrammeChoicesStep do
  subject(:step) { described_class.new(wizard:, use_same_programme_choices:) }

  let(:wizard) do
    instance_double(Schools::RegisterMentorWizard::Wizard)
  end

  let(:use_same_programme_choices) { 'yes' }

  describe '#previous_step' do
    it { expect(step.previous_step).to eq(:started_on) }
  end
end
