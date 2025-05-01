describe Schools::RegisterMentorWizard::CheckAnswersStep, type: :model do
  subject { wizard.current_step }

  let(:ect) { FactoryBot.create(:ect_at_school_period, :active, :provider_led) }
  let(:programme_type) { 'provider_led' }
  let(:use_previous_ect_choices) { true }
  let(:store) { FactoryBot.build(:session_repository) }
  let(:author) { FactoryBot.create(:school_user, school_urn: ect.school.urn) }
  let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :check_answers, store:, author:, ect_id: ect.id) }

  describe 'steps' do
    describe '#next_step' do
      it { expect(subject.next_step).to eq(:confirmation) }
    end

    describe '#previous_step' do
      context 'when the mentor is available for funding' do
        before do
          allow(wizard.mentor).to receive(:funding_available?).and_return(true)
        end

        context 'when the ect is provider led' do
          it { expect(subject.previous_step).to eq(:review_mentor_eligibility) }
        end

        context 'when the ect is not provider led' do
          let(:ect) { FactoryBot.create(:ect_at_school_period, :active, :school_led) }

          it { expect(subject.previous_step).to eq(:email_address) }
        end
      end

      context 'when the mentor is not available for funding' do
        before do
          allow(wizard.mentor).to receive(:funding_available?).and_return(false)
        end

        it { expect(subject.previous_step).to eq(:email_address) }
      end
    end
  end

  context '#save!' do
    let(:ect) { FactoryBot.create(:ect_at_school_period) }
    let(:ect_id) { ect.id }

    context 'when the step is not valid' do
      before do
        allow(wizard.current_step).to receive(:valid?).and_return(false)
      end

      it 'does not update any data in the wizard ect' do
        expect { subject.save! }.not_to change(subject.mentor, :registered)
      end
    end

    context 'when the step is valid' do
      let(:new_mentor) { double }

      before do
        allow(wizard.current_step).to receive(:valid?).and_return(true)
        allow(subject.mentor).to receive(:register!).and_return(new_mentor)
        allow(Schools::AssignMentor).to receive(:new).and_return(double(assign!: true))
        subject.save!
      end

      it 'registers the mentor' do
        expect(subject.mentor).to have_received(:register!)
      end

      it 'assigns the created mentor to the ECT' do
        expect(Schools::AssignMentor).to have_received(:new).with(ect: wizard.ect, mentor: new_mentor, author:)
      end
    end
  end
end
