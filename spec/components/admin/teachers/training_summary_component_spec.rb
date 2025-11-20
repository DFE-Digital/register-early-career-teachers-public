RSpec.describe Admin::Teachers::TrainingSummaryComponent, type: :component do
  subject(:rendered) { render_inline(described_class.new(training_period:)) }

  describe "provider-led training periods" do
    context "when the partnership is confirmed" do
      let(:training_period) { FactoryBot.create(:training_period, :provider_led) }

      before { rendered }

      it "shows the combined card title" do
        expect(rendered_content).to have_css(".govuk-summary-card__title", text: "#{training_period.lead_provider_name} & #{training_period.delivery_partner_name}")
      end

      it "shows the lead provider row" do
        expect(rendered_content).to have_css("dt", text: "Lead provider")
        expect(rendered_content).to have_css("dd", text: training_period.lead_provider_name)
      end

      it "shows the delivery partner row" do
        expect(rendered_content).to have_css("dt", text: "Delivery partner")
        expect(rendered_content).to have_css("dd", text: training_period.delivery_partner_name)
      end

      it "shows the school row" do
        expect(rendered_content).to have_css("dt", text: "School")
        expect(rendered_content).to have_css("dd", text: training_period.ect_at_school_period.school.name)
      end

      it "shows the contract period row" do
        expect(rendered_content).to have_css("dt", text: "Contract period")
        expect(rendered_content).to have_css("dd", text: training_period.contract_period.year)
      end

      it "shows the training programme row" do
        expect(rendered_content).to have_css("dt", text: "Training programme")
        expect(rendered_content).to have_css("dd", text: TRAINING_PROGRAMME[training_period.training_programme])
      end

      it "shows the schedule row" do
        expect(rendered_content).to have_css("dt", text: "Schedule")
        expect(rendered_content).to have_css("dd", text: training_period.schedule.description)
      end

      it "shows the start date row" do
        expect(rendered_content).to have_css("dt", text: "Start date")
        expect(rendered_content).to have_css("dd", text: training_period.started_on.to_fs(:govuk))
      end

      it "shows the end date row" do
        expect(rendered_content).to have_css("dt", text: "End date")
        expect(rendered_content).to have_css("dd", text: training_period.finished_on.to_fs(:govuk))
      end
    end

    context "when there is only an expression of interest" do
      let(:training_period) { FactoryBot.create(:training_period, :provider_led, :with_only_expression_of_interest) }

      before { rendered }

      it "omits the title and shows the placeholder delivery partner text" do
        expect(rendered_content).not_to have_css(".govuk-summary-card__title", text: /&/)
        expect(rendered_content).to have_css("dd", text: "No delivery partner confirmed")
      end

      it "falls back to the expression of interest contract period" do
        expect(rendered_content).to have_css("dt", text: "Contract period")
        expect(rendered_content).to have_css("dd", text: training_period.expression_of_interest_contract_period.year)
      end
    end

    context "when the period is for a mentor" do
      let(:training_period) { FactoryBot.create(:training_period, :provider_led, :for_mentor) }

      before { rendered }

      it "shows the mentor school name in the school row" do
        expect(rendered_content).to have_css("dt", text: "School")
        expect(rendered_content).to have_css("dd", text: training_period.mentor_at_school_period.school.name)
      end
    end
  end

  describe "school-led training periods" do
    let(:training_period) { FactoryBot.create(:training_period, :school_led) }

    before { rendered }

    it "sets a school-led card title" do
      expect(rendered_content).to have_css(".govuk-summary-card__title", text: "School-led training programme")
    end

    it "shows the school row" do
      expect(rendered_content).to have_css("dt", text: "School")
      expect(rendered_content).to have_css("dd", text: training_period.ect_at_school_period.school.name)
    end

    it "shows the training programme row" do
      expect(rendered_content).to have_css("dt", text: "Training programme")
      expect(rendered_content).to have_css("dd", text: TRAINING_PROGRAMME[:school_led])
    end

    it "shows the start date row" do
      expect(rendered_content).to have_css("dt", text: "Start date")
      expect(rendered_content).to have_css("dd", text: training_period.started_on.to_fs(:govuk))
    end

    it "shows the end date row" do
      expect(rendered_content).to have_css("dt", text: "End date")
      expect(rendered_content).to have_css("dd", text: training_period.finished_on.to_fs(:govuk))
    end
  end

  describe "#rows" do
    context "when the training programme type is unexpected" do
      let(:training_period) do
        instance_double(
          TrainingPeriod,
          provider_led_training_programme?: false,
          school_led_training_programme?: false,
          training_programme: "unexpected"
        )
      end

      it "raises an explicit error" do
        expect { described_class.new(training_period:).send(:rows) }.to raise_error(described_class::UnexpectedTrainingProgrammeError)
      end
    end
  end
end
