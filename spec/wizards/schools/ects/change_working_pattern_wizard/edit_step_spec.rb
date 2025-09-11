describe Schools::ECTs::ChangeWorkingPatternWizard::EditStep, type: :model do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::ECTs::ChangeWorkingPatternWizard::Wizard.new(
      current_step: :edit,
      step_params: ActionController::Parameters.new(edit: params),
      author:,
      store:,
      ect_at_school_period:
    )
  end
  let(:store) { FactoryBot.build(:session_repository) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school) }
  let(:ect_at_school_period) do
    FactoryBot.create(:ect_at_school_period, school:, working_pattern: "full_time")
  end
  let(:params) { { working_pattern: "full_time" } }

  describe ".permitted_params" do
    it "returns the permitted params" do
      expect(described_class.permitted_params).to contain_exactly(:working_pattern)
    end
  end

  describe "#previous_step" do
    it "raises an error" do
      expect { current_step.previous_step }.to raise_error(NotImplementedError)
    end
  end

  describe "#next_step" do
    it "returns the next step" do
      expect(current_step.next_step).to eq(:check_answers)
    end
  end

  describe "validations" do
    context "when working pattern is blank" do
      let(:params) { { working_pattern: "" } }

      it "is invalid" do
        expect(current_step).not_to be_valid
        expect(current_step.errors.messages_for(:working_pattern)).to contain_exactly(
          "Select a working pattern"
        )
      end
    end

    context "when working pattern is unchanged" do
      let(:params) { { working_pattern: ect_at_school_period.working_pattern } }

      it "is invalid" do
        expect(current_step).not_to be_valid
        expect(current_step.errors.messages_for(:working_pattern)).to contain_exactly(
          "The working pattern must be different from the current working pattern"
        )
      end
    end

    context "when working pattern is valid" do
      let(:params) { { working_pattern: "part_time" } }

      it "is valid" do
        expect(current_step).to be_valid
        expect(current_step.errors).to be_empty
      end
    end
  end
end
