describe Schools::ECTs::ChangeEmailAddressWizard::CheckAnswersStep, type: :model do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::ECTs::ChangeEmailAddressWizard::Wizard.new(
      current_step: :check_answers,
      step_params: ActionController::Parameters.new(check_answers: params),
      author:,
      store:,
      ect_at_school_period:
    )
  end
  let(:store) do
    FactoryBot.build(:session_repository, email: "new@example.com")
  end
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school) }
  let(:ect_at_school_period) do
    FactoryBot.create(:ect_at_school_period, school:, email: "old@example.com")
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
    it "updates the ECT's email" do
      expect { current_step.save! }
        .to change(ect_at_school_period, :email)
        .to("new@example.com")
    end

    it "records a `teacher_email_updated` event" do
      freeze_time

      expect(Events::Record)
        .to receive(:record_teacher_email_updated_event!)
        .with(
          old_email: "old@example.com",
          new_email: "new@example.com",
          author:,
          ect_at_school_period:,
          school:,
          teacher: ect_at_school_period.teacher,
          happened_at: Time.current
        )

      current_step.save!
    end

    it { is_expected.to be_truthy }
  end
end
