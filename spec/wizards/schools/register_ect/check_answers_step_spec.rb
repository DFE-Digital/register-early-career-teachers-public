describe Schools::RegisterECTWizard::CheckAnswersStep, type: :model do
  subject { described_class.new }

  describe '#next_step' do
    it 'returns :confirmation' do
      expect(subject.next_step).to eq(:confirmation)
    end
  end

  describe '#previous_step' do
    it 'returns :programme_type' do
      expect(subject.previous_step).to eq(:programme_type)
    end
  end

  context '#save!' do
    let(:school) { FactoryBot.create(:school) }
    let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :check_answers, school:) }

    subject { wizard.current_step }

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
