RSpec.describe Schools::AssignExistingMentorWizard::ReviewMentorEligibilityStep do
  subject(:step) { described_class.new(wizard:) }

  let(:ect_at_school_period) { instance_double(ECTAtSchoolPeriod) }
  let(:mentor_at_school_period) { instance_double(MentorAtSchoolPeriod) }
  let(:author) { instance_double(User) }

  let(:context) do
    instance_double(Schools::Shared::MentorAssignmentContext,
                    ect_at_school_period:,
                    mentor_at_school_period:)
  end

  let(:wizard) do
    instance_double(
      Schools::AssignExistingMentorWizard::Wizard,
      context:,
      author:
    )
  end

  describe '#next_step' do
    it 'returns :confirmation' do
      expect(step.next_step).to eq(:confirmation)
    end
  end
end
