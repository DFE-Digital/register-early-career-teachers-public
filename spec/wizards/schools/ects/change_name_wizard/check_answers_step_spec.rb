RSpec.describe Schools::ECTs::ChangeNameWizard::CheckAnswersStep, type: :model do
  subject(:current_step) { wizard.current_step }

  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period) }
  let(:school) { FactoryBot.create(:school, :independent) }
  let(:author) { FactoryBot.create(:school_user, school_urn: school.urn) }
  let(:store) { FactoryBot.build(:session_repository, name: 'Terry Pratchett') }

  let(:wizard) do
    FactoryBot.build(:change_ect_name_wizard,
                     current_step: :check_answers,
                     author:,
                     store:,
                     ect_at_school_period:)
  end

  describe '#next_step' do
    it { expect(current_step.next_step).to eq(:confirmation) }
  end

  describe '#previous_step' do
    it { expect(current_step.previous_step).to eq(:edit) }
  end

  describe '#save!' do
    it 'persists the corrected name' do
      expect { current_step.save! }.to change(wizard.ect_at_school_period.teacher, :corrected_name).from(nil).to('Terry Pratchett')
    end

    it 'records an event' do
      expect { current_step.save! }.to have_enqueued_job(RecordEventJob)
    end
  end
end
