RSpec.describe Schools::RegisterECTWizard::IndependentSchoolAppropriateBodyStep, type: :model do
  let(:school) { FactoryBot.create(:school, :independent) }

  describe '#initialize' do
    subject { described_class.new(wizard:, **params) }

    let(:store) { FactoryBot.build(:session_repository, appropriate_body_id: '123', appropriate_body_type: 'prepopulated_type') }
    let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :independent_school_appropriate_body, store:) }

    let(:appropriate_body_id) { 'provided_name' }
    let(:appropriate_body_type) { 'provided_type' }

    context 'when the appropriate_body_id is provided' do
      let(:params) { { appropriate_body_id:, appropriate_body_type: } }

      it 'populate the instance from it' do
        expect(subject.appropriate_body_id).to eq(appropriate_body_id)
        expect(subject.appropriate_body_type).to eq(appropriate_body_type)
      end
    end

    context 'when no attributes are provided' do
      let(:params) { {} }

      it 'populate it from the wizard store' do
        expect(subject.appropriate_body_id).to eq('123')
        expect(subject.appropriate_body_type).to eq('prepopulated_type')
      end
    end
  end

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

    context 'when the appropriate_body_type is present but the appropriate_body_id is not' do
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
      FactoryBot.build(:register_ect_wizard, current_step: :independent_school_appropriate_body, school:)
    end

    describe '#next_step' do
      it 'returns the next step' do
        expect(subject.next_step).to eq(:programme_type)
      end
    end

    describe '#previous_step' do
      context 'when the school has no programme choices' do
        it 'returns the previous step' do
          expect(subject.previous_step).to eq(:working_pattern)
        end
      end

      context 'when the school has programme choices' do
        let(:school) { FactoryBot.create(:school, :independent, :teaching_induction_panel_chosen, :school_led_chosen) }

        it 'returns the previous step' do
          expect(subject.previous_step).to eq(:use_previous_ect_choices)
        end
      end
    end
  end

  describe '#save!' do
    subject { wizard.current_step }

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
