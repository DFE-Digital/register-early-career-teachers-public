require_relative './shared_examples/email_step'

describe Schools::RegisterMentorWizard::EmailAddressStep, type: :model do
  context 'when email is in use' do
    before do
      allow(wizard.mentor).to receive(:cant_use_email?).and_return(true)
    end

    it_behaves_like 'an email step', current_step: :email_address,
                    previous_step: :review_mentor_details,
                    next_step: :cant_use_email
  end

  context 'with provider_led ect and without funding exemption' do
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

  context 'with school_led ect' do
    it_behaves_like 'an email step', current_step: :email_address,
                    previous_step: :review_mentor_details,
                    next_step: :check_answers do
      let(:ect) { FactoryBot.create(:ect_at_school_period, :active, :school_led) }
    end
  end
end
