require 'rails_helper'

RSpec.describe Schools::RegisterECTWizard::IndependentSchoolAppropriateBodyStep, type: :model do
  describe 'validations' do
    subject { described_class.new(appropriate_body_name:, appropriate_body_type:) }

    context 'when the appropriate_body_type is not present' do
      let(:appropriate_body_type) { nil }
      let(:appropriate_body_name) { nil }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:appropriate_body_type]).to include("Select the appropriate body which will be supporting the ECT's induction")
      end
    end

    context 'when the appropriate_body_type is present but the appropriate_body_name is not' do
      let(:appropriate_body_type) { 'teaching_school_hub' }
      let(:appropriate_body_name) { nil }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:appropriate_body_name]).to include("Enter the name of the appropriate body which will be supporting the ECT's induction")
      end
    end

    context 'when the appropriate_body_type is present and the appropriate_body_name is also present' do
      let(:appropriate_body_type) { 'teacher_school_hub' }
      let(:appropriate_body_name) { 'Some Teaching School Hub' }

      it 'is valid' do
        expect(subject).to be_valid
      end
    end
  end

  describe '#next_step' do
    let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :independent_school_appropriate_body) }

    subject { wizard.current_step }

    it 'returns the next step' do
      expect(subject.next_step).to eq(:programme_type)
    end
  end

  describe '#previous_step' do
    let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :independent_school_appropriate_body) }

    subject { wizard.current_step }

    it 'returns the previous step' do
      expect(subject.previous_step).to eq(:start_date)
    end
  end

  context '#save!' do
    let(:step_params) do
      ActionController::Parameters.new(
        "independent_school_appropriate_body" => {
          "appropriate_body_type" => 'teaching_school_hub',
          "appropriate_body_name" => 'Some Appropriate Body',
        }
      )
    end
    let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :independent_school_appropriate_body, step_params:) }

    subject { wizard.current_step }

    context 'when the step is not valid' do
      before do
        allow(subject).to receive(:valid?).and_return(false)
      end

      it 'does not update any data in the wizard ect' do
        expect { subject.save! }.not_to change(subject.ect, :appropriate_body_name)
      end
    end

    context 'when the step is valid' do
      before do
        allow(subject).to receive(:valid?).and_return(true)
      end

      it 'updates the wizard ect appropriate body name' do
        expect { subject.save! }
          .to change(subject.ect, :appropriate_body_name).from(nil).to('Some Appropriate Body')
      end
    end
  end
end
