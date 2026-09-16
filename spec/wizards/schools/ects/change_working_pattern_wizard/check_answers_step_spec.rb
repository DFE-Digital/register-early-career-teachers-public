describe Schools::ECTs::ChangeWorkingPatternWizard::CheckAnswersStep, type: :model do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::ECTs::ChangeWorkingPatternWizard::Wizard.new(
      current_step: :check_answers,
      step_params: ActionController::Parameters.new(check_answers: params),
      author:,
      store:,
      ect_at_school_period:
    )
  end
  let(:store) { FactoryBot.build(:session_repository, working_pattern: "part_time") }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school) }
  let(:ect_at_school_period) do
    FactoryBot.create(:ect_at_school_period, school:, working_pattern: "full_time")
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

  describe "#current_working_pattern" do
    it "returns the ECT's working pattern" do
      expect(current_step.current_working_pattern).to eq("full_time")
    end
  end

  describe "#new_working_pattern" do
    it "returns the stored working pattern" do
      expect(current_step.new_working_pattern).to eq("part_time")
    end
  end

  describe "#save!" do
    it "updates the ECT's working pattern" do
      expect { current_step.save! }
      .to change(ect_at_school_period, :working_pattern)
      .to("part_time")
    end

    it "records a `teacher_working_pattern_updated` event" do
      freeze_time

      current_step.save!

      event = Event.where(event_type: "teacher_working_pattern_updated").sole
      expect(event).to have_attributes(
        ect_at_school_period_id: ect_at_school_period.id,
        school_id: school.id,
        teacher_id: ect_at_school_period.teacher_id,
        happened_at: Time.current
      )
      expect(event.heading).to include("full time", "part time")
    end

    it "is truthy" do
      expect(current_step.save!).to be_truthy
    end
  end
end
