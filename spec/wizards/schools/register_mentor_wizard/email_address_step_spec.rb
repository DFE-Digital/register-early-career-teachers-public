require_relative './shared_examples/email_step'

describe Schools::RegisterMentorWizard::EmailAddressStep, type: :model do
  context 'without funding exemption' do
    it_behaves_like 'an email step', current_step: :email_address,
                                     previous_step: :review_mentor_details,
                                     next_step: :review_mentor_eligibility
  end

  context 'with funding exemption' do
    before do
      FactoryBot.create(:early_roll_out_mentor, trn: "1234567")
    end

    it_behaves_like 'an email step', current_step: :email_address,
                                     previous_step: :review_mentor_details,
                                     next_step: :check_answers
  end
end
