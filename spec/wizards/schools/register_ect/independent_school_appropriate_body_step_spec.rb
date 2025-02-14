RSpec.describe Schools::RegisterECTWizard::IndependentSchoolAppropriateBodyStep, type: :model do
  describe 'validations' do
    subject { described_class.new(appropriate_body_id:, appropriate_body_type:) }

    context 'when the appropriate_body_type is not present' do
      let(:appropriate_body_type) { nil }
      let(:appropriate_body_id) { nil }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:appropriate_body_type]).to include("Select the appropriate body which will be supporting the ECT's induction")
      end
    end

    context 'when the appropriate_body_type is present but the appropriate_body_name is not' do
      let(:appropriate_body_type) { 'teaching_school_hub' }
      let(:appropriate_body_id) { nil }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:appropriate_body_id]).to include("Enter the name of the appropriate body which will be supporting the ECT's induction")
      end
    end

    context 'when the appropriate_body_type is present and the appropriate_body_id is also present' do
      let(:appropriate_body_type) { 'teacher_school_hub' }
      let(:appropriate_body_id) { '1' }

      it { expect(subject).to be_valid }
    end
  end

  describe 'steps' do
    subject { wizard.current_step }

    let(:wizard) do
      FactoryBot.build(:register_ect_wizard, current_step: :independent_school_appropriate_body)
    end

    describe '#next_step' do
      it 'returns the next step' do
        expect(subject.next_step).to eq(:programme_type)
      end
    end

    describe '#previous_step' do
      it 'returns the previous step' do
        expect(subject.previous_step).to eq(:start_date)
      end
    end
  end

  describe '#save!' do
    let(:step_params) do
      ActionController::Parameters.new(
        "independent_school_appropriate_body" => {
          "appropriate_body_type" => 'teaching_school_hub',
          "appropriate_body_id" => '1',
        }
      )
    end

    let(:wizard) do
      FactoryBot.build(:register_ect_wizard, current_step: :independent_school_appropriate_body, step_params:)
    end

    subject { wizard.current_step }

    context 'when invalid' do
      before do
        allow(subject).to receive(:valid?).and_return(false)
      end

      it 'does not update any data in the wizard ect' do
        expect { subject.save! }.not_to change(subject.ect, :appropriate_body_id)
      end
    end

    context 'when valid' do
      before do
        allow(subject).to receive(:valid?).and_return(true)
      end

      it 'updates the wizard ect appropriate_body_id' do
        expect { subject.save! }.to change(subject.ect, :appropriate_body_id).from(nil).to('1')
      end
    end
  end
end
