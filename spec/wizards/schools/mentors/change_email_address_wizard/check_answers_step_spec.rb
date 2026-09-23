describe Schools::Mentors::ChangeEmailAddressWizard::CheckAnswersStep, type: :model do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::Mentors::ChangeEmailAddressWizard::Wizard.new(
      current_step: :check_answers,
      step_params: ActionController::Parameters.new(check_answers: params),
      author:,
      store:,
      mentor_at_school_period:
    )
  end
  let(:store) do
    FactoryBot.build(:session_repository, email: "new@example.com")
  end
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school) }
  let(:mentor_at_school_period) do
    FactoryBot.create(:mentor_at_school_period, school:, email: "old@example.com")
  end
  let(:params) { {} }

  describe "#previous_step" do
    it "returns the previous step" do
      expect(current_step.previous_step).to eq(:edit)
    end
  end

  describe "#next_step" do
    it "returns the next step" do
      expect(current_step.next_step).to eq(:confirmation)
    end
  end

  describe "#current_email" do
    it "returns the current email" do
      expect(current_step.current_email).to eq("old@example.com")
    end
  end

  describe "#new_email" do
    it "returns the new email" do
      expect(current_step.new_email).to eq("new@example.com")
    end
  end

  describe "save!" do
    it "updates the mentor's email" do
      expect { current_step.save! }
        .to change(mentor_at_school_period, :email)
        .to("new@example.com")
    end

    it "records a `teacher_email_updated` event" do
      freeze_time

      current_step.save!

      event = Event.where(event_type: "teacher_email_address_updated").sole
      expect(event).to have_attributes(
        mentor_at_school_period_id: mentor_at_school_period.id,
        school_id: school.id,
        teacher_id: mentor_at_school_period.teacher_id,
        happened_at: Time.current
      )
      expect(event.heading).to include("old@example.com", "new@example.com")
    end

    it "is truthy" do
      expect(current_step.save!).to be_truthy
    end
  end
end
