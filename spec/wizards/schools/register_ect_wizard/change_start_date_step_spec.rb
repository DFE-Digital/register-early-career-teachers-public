RSpec.describe Schools::RegisterECTWizard::ChangeStartDateStep, type: :model do
  subject(:step) { described_class.new(wizard:, start_date: new_start_date) }

  let(:school) { FactoryBot.create(:school, :state_funded) }

  let(:store) do
    FactoryBot.build(
      :session_repository,
      start_date: "3 September 2024",
      use_previous_ect_choices: true
    )
  end

  let(:wizard) do
    FactoryBot.build(
      :register_ect_wizard,
      current_step: :change_start_date,
      store:,
      school:
    )
  end

  before do
    store[:school_partnership_to_reuse_id] = 123
  end

  describe "#next_step" do
    context "when start date is in the past" do
      let(:new_start_date) { "1 July 2024" }

      it "goes to check answers" do
        expect(step.next_step).to eq(:check_answers)
      end
    end

    context "when start date is in the future" do
      let(:new_start_date) { "1 July 2030" }

      it "goes to check answers" do
        expect(step.next_step).to eq(:check_answers)
      end
    end
  end

  describe "#previous_step" do
    let(:new_start_date) { "1 July 2024" }

    it "always goes back to check answers" do
      expect(step.previous_step).to eq(:check_answers)
    end
  end

  describe "#save!" do
    let(:new_start_date) { "1 July 2024" }

    it "updates the wizard ect start date" do
      expect { step.save! }
        .to change(step.ect, :start_date)
        .to("1 July 2024")
    end

    it "clears stored school_partnership_to_reuse_id" do
      expect(store[:school_partnership_to_reuse_id]).to eq(123)

      step.save!

      expect(store[:school_partnership_to_reuse_id]).to be_nil
    end

    it "clears use_previous_ect_choices on the ect" do
      step.save!
      expect(wizard.ect.use_previous_ect_choices).to be_nil
    end

    context "when programme choices are already set" do
      before do
        wizard.ect.appropriate_body_id = 99
        wizard.ect.training_programme = "provider_led"
        wizard.ect.lead_provider_id = 42
      end

      it "does not clear programme choices" do
        step.save!

        expect(wizard.ect.appropriate_body_id).to eq(99)
        expect(wizard.ect.training_programme).to eq("provider_led")
        expect(wizard.ect.lead_provider_id).to eq(42)
      end
    end
  end
end
