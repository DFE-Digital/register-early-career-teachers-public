describe Schools::RegisterECTWizard::CheckAnswersStep, type: :model do
  subject(:step) { wizard.current_step }

  let(:training_programme) { "provider_led" }
  let(:use_previous_ect_choices) { true }
  let(:school) { FactoryBot.build(:school, :independent) }
  let(:store)  { FactoryBot.build(:session_repository, use_previous_ect_choices:, training_programme:) }

  let(:wizard) do
    FactoryBot.build(
      :register_ect_wizard,
      current_step: :check_answers,
      store:,
      school:
    )
  end

  describe "steps" do
    describe "#next_step" do
      it "always goes to confirmation" do
        expect(step.next_step).to eq(:confirmation)
      end
    end

    describe "#previous_step" do
      context "when school choices have been used" do
        let(:use_previous_ect_choices) { true }

        it "returns :use_previous_ect_choices" do
          expect(step.previous_step).to eq(:use_previous_ect_choices)
        end
      end

      context "when school choices have not been used" do
        let(:use_previous_ect_choices) { false }

        context "when the ect training_programme is school_led" do
          let(:training_programme) { "school_led" }

          it "returns :training_programme" do
            expect(step.previous_step).to eq(:training_programme)
          end
        end

        context "when the ect training_programme is provider_led" do
          let(:training_programme) { "provider_led" }

          it "returns :lead_provider" do
            expect(step.previous_step).to eq(:lead_provider)
          end
        end
      end
    end
  end

  describe "#save!" do
    context "when the step is not valid" do
      before do
        allow(step).to receive(:valid?).and_return(false)
      end

      it "does not update any data in the wizard ect" do
        expect { step.save! }.not_to change(step.ect, :ect_at_school_period_id)
      end
    end

    context "when the step is valid" do
      before do
        allow(step).to receive(:valid?).and_return(true)
        allow(step.ect).to receive(:register!).and_return(OpenStruct.new(id: 1))
      end

      it "updates the wizard ect ect_at_school_period_id" do
        expect { step.save! }
          .to change(step.ect, :ect_at_school_period_id).from(nil).to(1)
      end
    end
  end

  describe "#show_previous_programme_choices_row?" do
    before do
      allow(wizard).to receive(:use_previous_choices_allowed?).and_return(true)
    end

    context "when the school has last programme choices and reuse step is allowed" do
      before do
        allow(school).to receive(:last_programme_choices?).and_return(true)
      end

      it "returns true" do
        expect(step.show_previous_programme_choices_row?).to be(true)
      end
    end

    context "when the school does not have last programme choices" do
      before do
        allow(school).to receive(:last_programme_choices?).and_return(false)
      end

      it "returns false" do
        expect(step.show_previous_programme_choices_row?).to be(false)
      end
    end

    context "when reuse previous choices step is not allowed" do
      before do
        allow(school).to receive(:last_programme_choices?).and_return(true)
        allow(wizard).to receive(:use_previous_choices_allowed?).and_return(false)
      end

      it "returns false" do
        expect(step.show_previous_programme_choices_row?).to be(false)
      end
    end
  end
end
