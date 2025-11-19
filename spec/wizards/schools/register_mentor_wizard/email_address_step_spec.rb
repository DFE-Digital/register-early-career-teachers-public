require_relative "./shared_examples/email_step"

describe Schools::RegisterMentorWizard::EmailAddressStep, type: :model do
  context "when email is in use" do
    before do
      allow(wizard.mentor).to receive(:email_taken?).and_return(true)
    end

    it_behaves_like "an email step", current_step: :email_address,
                                     previous_step: :review_mentor_details,
                                     next_step: :cant_use_email
  end

  context "with provider_led ect and without funding exemption" do
    before do
      allow(wizard.mentor).to receive(:ect_lead_provider_invalid?).and_return(false)
    end

    it_behaves_like "an email step", current_step: :email_address,
                                     previous_step: :review_mentor_details,
                                     next_step: :review_mentor_eligibility,
                                     training_programme: :provider_led
  end

  context "with funding exemption" do
    before do
      allow(wizard.mentor).to receive(:ect_lead_provider_invalid?).and_return(false)
      FactoryBot.create(:teacher, :early_roll_out_mentor, trn: "1234567")
    end

    it_behaves_like "an email step", current_step: :email_address,
                                     previous_step: :review_mentor_details,
                                     next_step: :check_answers
  end

  context "with school_led ect" do
    before do
      allow(wizard.mentor).to receive(:ect_lead_provider_invalid?).and_return(false)
    end

    it_behaves_like "an email step", current_step: :email_address,
                                     previous_step: :review_mentor_details,
                                     next_step: :check_answers,
                                     training_programme: :school_led
  end

  context "provider-led, eligible for funding, previously registered, previously a mentor" do
    before do
      allow(wizard.mentor).to receive_messages(email_taken?: false, eligible_for_funding?: true, previously_registered_as_mentor?: true, mentorship_status: :previously_a_mentor)
    end

    it_behaves_like "an email step",
                    current_step: :email_address,
                    previous_step: :review_mentor_details,
                    next_step: :started_on,
                    training_programme: :provider_led
  end

  context "provider-led, eligible for funding, previously registered, currently a mentor" do
    before do
      allow(wizard.mentor).to receive_messages(email_taken?: false, eligible_for_funding?: true, previously_registered_as_mentor?: true, mentorship_status: :currently_a_mentor)
    end

    it_behaves_like "an email step",
                    current_step: :email_address,
                    previous_step: :review_mentor_details,
                    next_step: :mentoring_at_new_school_only,
                    training_programme: :provider_led
  end

  context "previously registered with unexpected mentorship_status" do
    let(:ect) { FactoryBot.create(:ect_at_school_period, :ongoing) }
    let(:store) do
      FactoryBot.build(:session_repository,
                       trn: "1234567",
                       trs_first_name: "Naruto",
                       trs_last_name: "Uzumaki",
                       corrected_name: "9 tails fox",
                       date_of_birth: "01/01/1990",
                       email: "uchiha@clan.com")
    end
    let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :email_address, store:, ect_id: ect.id) }

    before do
      FactoryBot.create(:training_period, :provider_led, :ongoing, ect_at_school_period: ect)
      allow(wizard.mentor).to receive_messages(
        email_taken?: false,
        previously_registered_as_mentor?: true,
        mentorship_status: :unknown_state
      )
    end

    it "raises InvalidMentorshipStatus" do
      expect { described_class.new(wizard:).next_step }
        .to raise_error(described_class::InvalidMentorshipStatus, /Unexpected status: :unknown_state/)
    end
  end

  context "when ect lead provider is not valid for mentor contract period" do
    before do
      allow(wizard.mentor).to receive_messages(
        email_taken?: false,
        previously_registered_as_mentor?: false,
        eligible_for_funding?: true,
        ect_lead_provider_invalid?: true
      )
    end

    it_behaves_like "an email step",
                    current_step: :email_address,
                    previous_step: :review_mentor_details,
                    next_step: :lead_provider,
                    training_programme: :provider_led
  end
end
