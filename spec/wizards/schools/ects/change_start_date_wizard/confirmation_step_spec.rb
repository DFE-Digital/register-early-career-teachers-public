RSpec.describe Schools::ECTs::ChangeStartDateWizard::ConfirmationStep,
               type: :model do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::ECTs::ChangeStartDateWizard::Wizard.new(
      current_step: :confirmation,
      step_params: ActionController::Parameters.new(
        confirmation: {}
      ),
      author:,
      store:,
      ect_at_school_period:
    )
  end

  let(:store) do
    FactoryBot.build(:session_repository)
  end

  let(:school) { FactoryBot.create(:school) }

  let(:author) do
    FactoryBot.build(
      :school_user,
      school_urn: school.urn
    )
  end

  let(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      :unfinished,
      school:,
      started_on: Date.new(2024, 9, 1)
    )
  end

  describe "#previous_step" do
    it "returns check answers" do
      expect(current_step.previous_step)
        .to eq(:check_answers)
    end
  end

  describe "#new_start_date" do
    it "returns the updated school start date" do
      expect(current_step.new_start_date)
        .to eq(Date.new(2024, 9, 1))
    end
  end
end
