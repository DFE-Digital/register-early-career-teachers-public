require_relative './shared_examples/review_mentor_details_step'

describe Schools::RegisterMentorWizard::ReviewMentorDetailsStep, type: :model do
  it_behaves_like 'a review mentor details step',
                  current_step: :review_mentor_details,
                  next_step: :email_address

  describe '#previous_step' do
    subject { wizard.current_step }

    let(:store) do
      FactoryBot.build(:session_repository,
                       trn: '1234567',
                       trs_first_name: 'John',
                       trs_last_name: 'Wayne',
                       change_name: 'yes',
                       corrected_name: 'Jim Wayne',
                       date_of_birth: '01/01/1990',
                       email: 'initial@email.com')
    end
    let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :review_mentor_details, store:) }

    context "when the date of birth matches TRS" do
      before { allow(wizard.mentor).to receive(:matches_trs_dob?).and_return(true) }

      it { expect(subject.previous_step).to eq(:find_mentor) }
    end

    context "when the date of birth doesn't match TRS" do
      before { allow(wizard.mentor).to receive(:matches_trs_dob?).and_return(false) }

      it { expect(subject.previous_step).to eq(:national_insurance_number) }
    end
  end
end
