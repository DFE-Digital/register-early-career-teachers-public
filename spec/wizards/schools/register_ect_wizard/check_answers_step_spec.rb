describe Schools::RegisterECTWizard::CheckAnswersStep, type: :model do
  subject { wizard.current_step }

  describe 'steps' do
    let(:wizard) do
      FactoryBot.build(:register_ect_wizard, current_step: :check_answers)
    end

    describe '#next_step' do
      it 'returns the next step' do
        expect(subject.next_step).to eq(:confirmation)
      end
    end

    describe '#previous_step' do
      context 'when the ect programme_type is school_led' do
        before do
          allow(wizard.ect).to receive(:provider_led?).and_return(false)
        end

        it 'returns :programme_type' do
          expect(subject.previous_step).to eq(:programme_type)
        end
      end

      context 'when the ect programme_type is provider_led' do
        before do
          allow(wizard.ect).to receive(:provider_led?).and_return(true)
        end

        it 'returns :lead_provider' do
          expect(subject.previous_step).to eq(:lead_provider)
        end
      end
    end
  end

  context '#save!' do
    let(:school) { FactoryBot.create(:school) }
    let(:store) { FactoryBot.build(:session_repository, school_urn: school.urn) }
    let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :check_answers, store:) }

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
