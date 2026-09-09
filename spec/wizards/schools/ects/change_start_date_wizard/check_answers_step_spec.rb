RSpec.describe Schools::ECTs::ChangeStartDateWizard::CheckAnswersStep,
               type: :model do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::ECTs::ChangeStartDateWizard::Wizard.new(
      current_step: :check_answers,
      step_params: ActionController::Parameters.new(
        check_answers: params
      ),
      author:,
      store:,
      ect_at_school_period:
    )
  end

  let(:params) { {} }

  let(:store) do
    FactoryBot.build(
      :session_repository,
      start_date: {
        "1" => "2024",
        "2" => "9",
        "3" => "1"
      }
    )
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
      started_on: Date.new(2024, 1, 1)
    )
  end

  describe "#previous_step" do
    it "returns edit" do
      expect(current_step.previous_step).to eq(:edit)
    end
  end

  describe "#next_step" do
    it "returns confirmation" do
      expect(current_step.next_step).to eq(:confirmation)
    end
  end

  describe "#current_start_date" do
    it "returns the ECT's current school start date" do
      expect(current_step.current_start_date)
        .to eq(Date.new(2024, 1, 1))
    end
  end

  describe "#new_start_date" do
    it "returns the stored start date as a Date" do
      expect(current_step.new_start_date)
        .to eq(Date.new(2024, 9, 1))
    end
  end

  describe "#save!" do
    before do
      allow(ECTAtSchoolPeriods::ChangeStartDate)
        .to receive(:change)
    end

    it "changes the ECT's school start date" do
      expect(ECTAtSchoolPeriods::ChangeStartDate)
        .to receive(:change)
        .with(
          ect_at_school_period,
          started_on: Date.new(2024, 9, 1),
          author:
        )

      current_step.save!
    end

    it "is truthy" do
      expect(current_step.save!).to be_truthy
    end
  end
end
