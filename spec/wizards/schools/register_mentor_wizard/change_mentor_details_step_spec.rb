require_relative './shared_examples/review_mentor_details_step'

describe Schools::RegisterMentorWizard::ChangeMentorDetailsStep, type: :model do
  it_behaves_like 'a review mentor details step',
                  current_step: :change_mentor_details,
                  next_step: :check_answers

  describe '#previous_step' do
    subject { wizard.current_step }

    let(:store) do
      build(:session_repository,
            trn: '1234567',
            trs_first_name: 'John',
            trs_last_name: 'Wayne',
            change_name: 'yes',
            corrected_name: 'Jim Wayne',
            date_of_birth: '01/01/1990',
            email: 'initial@email.com')
    end
    let(:wizard) { build(:register_mentor_wizard, current_step: :change_mentor_details, store:) }

    it { expect(subject.previous_step).to eq(:check_answers) }
  end
end
