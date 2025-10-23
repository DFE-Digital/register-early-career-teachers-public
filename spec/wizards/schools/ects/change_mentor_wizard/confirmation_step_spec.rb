describe Schools::ECTs::ChangeMentorWizard::ConfirmationStep, type: :model do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::ECTs::ChangeMentorWizard::Wizard.new(
      current_step: :confirmation,
      step_params: ActionController::Parameters.new(confirmation: params),
      author:,
      store:,
      ect_at_school_period:
    )
  end
  let(:store) { FactoryBot.build(:session_repository) }
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
  let!(:mentorship_period) do
    FactoryBot.create(
      :mentorship_period,
      :ongoing,
      mentee: ect_at_school_period,
      mentor: mentor_at_school_period,
      started_on: ect_at_school_period.started_on
    )
  end
  let(:params) { {} }

  describe "#previous_step" do
    it "returns the previous step" do
      expect(current_step.previous_step).to eq(:check_answers)
    end
  end

  describe "#next_step" do
    it "raises an error" do
      expect { current_step.next_step }.to raise_error(NotImplementedError)
    end
  end

  describe "#current_mentor_name" do
    it "returns the current mentor's teacher's name" do
      expect(current_step.current_mentor_name)
        .to eq(Teachers::Name.new(mentor_at_school_period.teacher).full_name)
    end
  end
end
