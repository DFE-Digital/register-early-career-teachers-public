describe Schools::RegisterECTWizard::CheckAnswersStep, type: :model do
  subject { wizard.current_step }

  let(:training_programme) { 'provider_led' }
  let(:use_previous_ect_choices) { true }
  let(:school) { build(:school, :independent) }
  let(:store) { build(:session_repository, use_previous_ect_choices:, training_programme:) }
  let(:wizard) { build(:register_ect_wizard, current_step: :check_answers, store:, school:) }

  describe 'steps' do
    describe '#next_step' do
      it { expect(subject.next_step).to eq(:confirmation) }
    end

    describe '#previous_step' do
      context 'when school choices has been used' do
        let(:use_previous_ect_choices) { true }

        it { expect(subject.previous_step).to eq(:use_previous_ect_choices) }
      end

      context 'when school choices has not been used' do
        let(:use_previous_ect_choices) { false }

        context 'when the ect training_programme is school_led' do
          let(:training_programme) { 'school_led' }

          it 'returns :training_programme' do
            expect(subject.previous_step).to eq(:training_programme)
          end
        end

        context 'when the ect training_programme is provider_led' do
          let(:training_programme) { 'provider_led' }

          it 'returns :lead_provider' do
            expect(subject.previous_step).to eq(:lead_provider)
          end
        end
      end
    end
  end

  context '#save!' do
    context 'when the step is not valid' do
      before do
        allow(subject).to receive(:valid?).and_return(false)
      end

      it 'does not update any data in the wizard ect' do
        expect { subject.save! }.not_to change(subject.ect, :ect_at_school_period_id)
      end
    end

    context 'when the step is valid' do
      before do
        allow(subject).to receive(:valid?).and_return(true)
        allow(subject.ect).to receive(:register!).and_return(OpenStruct.new(id: 1))
      end

      it 'updates the wizard ect ect_at_school_period_id' do
        expect { subject.save! }
          .to change(subject.ect, :ect_at_school_period_id).from(nil).to(1)
      end
    end
  end
end
