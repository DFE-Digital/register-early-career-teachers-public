RSpec.describe Schools::RegisterMentorWizard::ProgrammeChoicesStep do
  subject(:step) { described_class.new(wizard:, use_same_programme_choices:) }

  let(:wizard) do
    instance_double(Schools::RegisterMentorWizard::Wizard)
  end

  let(:error_message) { "Select 'Yes' or 'No' to confirm whether to use the programme choices used by your school previously" }
  let(:use_same_programme_choices) { 'yes' }

  describe '#previous_step' do
    it { expect(step.previous_step).to eq(:started_on) }
  end

  describe '#valid?' do
    context 'when blank' do
      let(:use_same_programme_choices) { nil }

      it 'is invalid with correct error' do
        expect(step).not_to be_valid
        expect(step.errors[:use_same_programme_choices]).to include(error_message)
      end
    end

    context 'when yes' do
      it 'is valid' do
        expect(step).to be_valid
      end
    end

    context 'when no' do
      let(:use_same_programme_choices) { 'no' }

      it 'is valid' do
        expect(step).to be_valid
      end
    end
  end
end
