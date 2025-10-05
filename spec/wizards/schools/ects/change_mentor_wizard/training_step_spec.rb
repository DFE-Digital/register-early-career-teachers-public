describe Schools::ECTs::ChangeMentorWizard::TrainingStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::ECTs::ChangeMentorWizard::Wizard.new(
      current_step: :training,
      step_params: ActionController::Parameters.new(training: params),
      author:,
      store:,
      ect_at_school_period:
    )
  end
  let(:store) do
    FactoryBot.build(
      :session_repository,
      mentor_at_school_period_id: mentor_at_school_period.id
    )
  end
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school) }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:) }
  let(:mentor_at_school_period) do
    FactoryBot.create(
      :mentor_at_school_period,
      :ongoing,
      school:,
      started_on: ect_at_school_period.started_on - 1.month
    )
  end
  let(:params) { { accepting_current_lead_provider: "true" } }

  describe ".permitted_params" do
    it "returns the permitted parameters" do
      expect(described_class.permitted_params)
        .to contain_exactly(:accepting_current_lead_provider)
    end
  end

  describe "#previous_step" do
    it "returns the edit step" do
      expect(current_step.previous_step).to eq(:edit)
    end
  end

  describe "#next_step" do
    it "returns the check answers step" do
      expect(current_step.next_step).to eq(:check_answers)
    end
  end

  describe "#new_mentor" do
    it "returns the teacher from the selected mentor_at_school_period" do
      expect(current_step.new_mentor).to eq(mentor_at_school_period.teacher)
    end
  end

  describe "#save!" do
    it "stores the accepting_current_lead_provider" do
      expect { current_step.save! }
        .to change(store, :accepting_current_lead_provider)
        .from(nil).to(true)
    end

    it "is truthy" do
      expect(current_step.save!).to be_truthy
    end
  end
end
