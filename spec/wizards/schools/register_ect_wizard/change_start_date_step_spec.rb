RSpec.describe Schools::RegisterECTWizard::ChangeStartDateStep, type: :model do
  subject(:step) { described_class.new(wizard:, start_date: new_start_date) }

  let(:new_start_date) { "1 July 2024" }
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
    context "when the school has last programme choices and reuse is still allowed" do
      before do
        allow(school).to receive(:last_programme_choices?).and_return(true)
        allow(wizard).to receive(:use_previous_choices_allowed?).and_return(true)
      end

      it "goes back to the reuse choices step" do
        expect(step.next_step).to eq(:use_previous_ect_choices)
      end
    end

    context "when the school has last programme choices but reuse is no longer allowed" do
      before do
        allow(school).to receive(:last_programme_choices?).and_return(true)
        allow(wizard).to receive(:use_previous_choices_allowed?).and_return(false)
      end

      context "and the school is independent" do
        let(:school) { FactoryBot.create(:school, :independent) }

        it "falls back to the independent appropriate body step" do
          expect(step.next_step).to eq(:independent_school_appropriate_body)
        end
      end

      context "and the school is state funded" do
        let(:school) { FactoryBot.create(:school, :state_funded) }

        it "falls back to the state-school appropriate body step" do
          expect(step.next_step).to eq(:state_school_appropriate_body)
        end
      end
    end

    context "when the school does not have last programme choices" do
      before do
        allow(school).to receive(:last_programme_choices?).and_return(false)
        allow(wizard).to receive(:use_previous_choices_allowed?).and_return(true)
      end

      context "and the school is independent" do
        let(:school) { FactoryBot.create(:school, :independent) }

        it "goes to independent appropriate body step" do
          expect(step.next_step).to eq(:independent_school_appropriate_body)
        end
      end

      context "and the school is state funded" do
        let(:school) { FactoryBot.create(:school, :state_funded) }

        it "goes to state-school appropriate body step" do
          expect(step.next_step).to eq(:state_school_appropriate_body)
        end
      end
    end
  end

  describe "#previous_step" do
    it "always goes back to check answers" do
      expect(step.previous_step).to eq(:check_answers)
    end
  end

  describe "#save!" do
    it "updates the wizard ect start date" do
      expect { step.save! }
        .to change(step.ect, :start_date)
        .to("1 July 2024")
    end

    it "resets use_previous_ect_choices on the ect" do
      expect { step.save! }
        .to change(step.ect, :use_previous_ect_choices)
        .to(nil)
    end

    it "clears stored school_partnership_to_reuse_id" do
      expect(store[:school_partnership_to_reuse_id]).to eq(123)
      step.save!
      expect(store[:school_partnership_to_reuse_id]).to be_nil
    end

    context "when reuse is no longer allowed" do
      before do
        allow(wizard).to receive(:use_previous_choices_allowed?).and_return(false)

        wizard.ect.appropriate_body_id = 99
        wizard.ect.training_programme = "provider_led"
        wizard.ect.lead_provider_id = 42
      end

      it "clears programme choices" do
        step.save!

        expect(wizard.ect.appropriate_body_id).to be_nil
        expect(wizard.ect.training_programme).to be_nil
        expect(wizard.ect.lead_provider_id).to be_nil
      end
    end

    context "when reuse is still allowed" do
      before do
        allow(wizard).to receive(:use_previous_choices_allowed?).and_return(true)

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
