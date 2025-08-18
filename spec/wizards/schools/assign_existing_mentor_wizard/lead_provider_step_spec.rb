RSpec.describe Schools::AssignExistingMentorWizard::LeadProviderStep do
  subject(:step) { described_class.new(wizard:, lead_provider_id:) }

  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:lead_provider_id) { lead_provider.id }
  let(:ect_at_school_period) { instance_double(ECTAtSchoolPeriod) }
  let(:mentor_at_school_period) { instance_double(MentorAtSchoolPeriod) }
  let(:author) { instance_double(User) }

  let(:context) do
    instance_double(
      Schools::Shared::MentorAssignmentContext,
      ect_at_school_period:,
      mentor_at_school_period:
    )
  end

  let(:wizard) do
    instance_double(
      Schools::AssignExistingMentorWizard::Wizard,
      context:,
      author:
    )
  end

  describe '#valid?' do
    context 'when lead_provider_id is nil' do
      let(:lead_provider_id) { nil }

      it 'is invalid with correct error' do
        expect(step).not_to be_valid
        expect(step.errors[:lead_provider_id]).to include('Select a lead provider to contact your school')
      end
    end

    context 'when lead_provider_id is present' do
      it 'is valid' do
        expect(step).to be_valid
      end
    end
  end

  describe '#next_step' do
    it { expect(step.next_step).to eq(:confirmation) }
  end

  describe '#previous_step' do
    it { expect(step.previous_step).to eq(:review_mentor_eligibility) }
  end

  describe '#save' do
    let(:store) { OpenStruct.new(lead_provider_id: nil) }
    let(:assign_mentor_double) { instance_double(Schools::AssignMentor, assign!: true) }

    let(:wizard) do
      instance_double(
        Schools::AssignExistingMentorWizard::Wizard,
        context:,
        author:,
        store:,
        valid_step?: true
      )
    end

    before do
      allow(Schools::AssignMentor).to receive(:new).and_return(assign_mentor_double)
    end

    it 'persists the selected lead_provider_id to the store' do
      expect { step.save! }.to change(store, :lead_provider_id).from(nil).to(lead_provider_id)
    end
  end
end
