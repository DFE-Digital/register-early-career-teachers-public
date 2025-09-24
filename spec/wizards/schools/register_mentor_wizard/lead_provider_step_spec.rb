RSpec.describe Schools::RegisterMentorWizard::LeadProviderStep, type: :model do
  subject { wizard.current_step }

  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing) }
  let(:store) { FactoryBot.build(:session_repository) }
  let(:author) { FactoryBot.create(:school_user, school_urn: ect_at_school_period.school.urn) }
  let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :lead_provider, store:, author:, ect_id: ect_at_school_period.id) }

  describe 'steps' do
    describe '#next_step' do
      it { expect(subject.next_step).to eq(:check_answers) }
    end

    describe '#previous_step' do
      context 'when the ect lead provider is invalid' do
        before { allow(wizard.mentor).to receive(:ect_lead_provider_invalid?).and_return(true) }

        it { expect(subject.previous_step).to eq(:email_address) }
      end

      context 'when the ect lead provider is valid' do
        before { allow(wizard.mentor).to receive(:ect_lead_provider_invalid?).and_return(false) }

        it { expect(subject.previous_step).to eq(:programme_choices) }
      end
    end
  end
end
