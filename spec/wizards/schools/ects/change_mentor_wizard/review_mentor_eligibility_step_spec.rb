describe Schools::ECTs::ChangeMentorWizard::ReviewMentorEligibilityStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::ECTs::ChangeMentorWizard::Wizard.new(
      current_step: :review_mentor_eligibility,
      step_params: ActionController::Parameters.new(review_mentor_eligibility: params),
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
  let(:ect_at_school_period) do
    FactoryBot.create(:ect_at_school_period, :ongoing, school:)
  end
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

  describe "#current_lead_provider_name" do
    let!(:training_period) do
      FactoryBot.create(
        :training_period,
        :ongoing,
        :with_school_partnership,
        ect_at_school_period:,
        started_on: ect_at_school_period.started_on
      )
    end

    it "returns the lead provider's name from the ECT's current lead provider" do
      expect(current_step.current_lead_provider_name)
        .to eq(training_period.lead_provider.name)
    end
  end

  describe "#new_mentor_name" do
    it "returns the teacher's name from the selected mentor_at_school_period" do
      expect(current_step.new_mentor_name)
        .to eq(Teachers::Name.new(mentor_at_school_period.teacher).full_name)
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
