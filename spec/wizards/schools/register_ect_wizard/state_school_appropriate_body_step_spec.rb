RSpec.describe Schools::RegisterECTWizard::StateSchoolAppropriateBodyStep, type: :model do
  let(:school) { FactoryBot.create(:school, :state_funded) }
  let(:store) { FactoryBot.build(:session_repository, appropriate_body_id: '123') }
  let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :state_school_appropriate_body, store:, school:) }

  describe 'validations' do
    subject { described_class.new(wizard:, appropriate_body_id:) }

    context 'when the appropriate_body is a national' do
      let(:appropriate_body_id) { FactoryBot.create(:appropriate_body, :national).id }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:appropriate_body]).to include("Select a teaching school hub appropriate body which will be supporting the ECT's induction")
      end
    end

    context 'when the appropriate_body is a teaching school hub' do
      let(:appropriate_body_id) { FactoryBot.create(:appropriate_body, :teaching_school_hub).id }
      let(:appropriate_body_type) { 'teaching_school_hub' }

      it 'adds no error' do
        expect(subject).to be_valid
      end
    end
  end

  describe 'steps' do
    subject { wizard.current_step }

    describe '#next_step' do
      it 'returns the next step' do
        expect(subject.next_step).to eq(:training_programme)
      end
    end
  end
end
