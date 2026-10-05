describe Schools::ECTs::ChangeAppropriateBodyWizard::ConfirmationStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::ECTs::ChangeAppropriateBodyWizard::Wizard.new(
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
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:, school_reported_appropriate_body:) }
  let(:school_reported_appropriate_body) { FactoryBot.create(:appropriate_body_period) }
  let(:params) { {} }

  describe "#previous_step" do
    it "returns the check answers step" do
      expect(current_step.previous_step).to eq(:check_answers)
    end
  end

  describe "#next_step" do
    it "raises an error" do
      expect { current_step.next_step }.to raise_error(NotImplementedError)
    end
  end

  describe "#new_appropriate_body_name" do
    let(:store) do
      FactoryBot.build(:session_repository, appropriate_body_id: appropriate_body_period.id)
    end

    context "when the period has a name of its own" do
      let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name: "Star Institute") }

      it "returns it" do
        expect(current_step.new_appropriate_body_name).to eq("Star Institute")
      end
    end

    context "when the period has no name of its own" do
      let(:teaching_school_hub) { FactoryBot.create(:teaching_school_hub, name: "Star Teaching School Hub Network") }
      let(:appropriate_body_period) do
        FactoryBot.create(:appropriate_body_period, :teaching_school_hub, name: nil, teaching_school_hub:)
      end

      it "delegates to the parent hub" do
        expect(current_step.new_appropriate_body_name).to eq("Star Teaching School Hub Network")
      end
    end
  end
end
