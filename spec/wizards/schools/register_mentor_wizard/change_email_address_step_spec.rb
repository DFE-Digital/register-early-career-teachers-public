require_relative "./shared_examples/email_step"

describe Schools::RegisterMentorWizard::ChangeEmailAddressStep, type: :model do
  context "when email is in use" do
    before do
      allow(subject.mentor).to receive(:email_taken?).and_return(true)
    end

    it_behaves_like "an email step",
                    current_step: :change_email_address,
                    previous_step: :cant_use_changed_email,
                    next_step: :cant_use_changed_email
  end

  context "when email is not in use" do
    it_behaves_like "an email step",
                    current_step: :change_email_address,
                    previous_step: :check_answers,
                    next_step: :check_answers
  end

  describe "#save!" do
    let(:ect) { FactoryBot.create(:ect_at_school_period, :unfinished) }
    let(:selected_lead_provider) { FactoryBot.create(:lead_provider) }
    let(:store) { FactoryBot.build(:session_repository, trn: "1234567", email: "initial@email.com", lead_provider_id: selected_lead_provider.id) }
    let(:step_params) { ActionController::Parameters.new("change_email_address" => { "email" => "changed@email.com" }) }
    let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :change_email_address, store:, step_params:, ect_id: ect.id) }

    before { FactoryBot.create(:training_period, :provider_led, :unfinished, ect_at_school_period: ect) }

    it "keeps the lead provider already selected" do
      wizard.save!

      expect(store.email).to eq("changed@email.com")
      expect(store.lead_provider_id).to eq(selected_lead_provider.id)
    end
  end
end
