RSpec.describe Admin::Teachers::TrainingSummaryComponent, type: :component do
  subject(:rendered) { render_inline(described_class.new(training_period:)) }

  describe "provider-led training periods" do
    let(:teacher) { metadata.teacher }

    context "when the period is for an ECT" do
      let!(:metadata) { FactoryBot.create(:teacher_lead_provider_metadata, :with_latest_ect_training_period) }
      let(:training_period) { metadata.latest_ect_training_period }

      before do
        training_period.update!(finished_on: 1.week.ago)
        rendered
      end

      context "when the partnership is confirmed" do
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
          expect(rendered_content).to have_css("dd", text: training_period.schedule.identifier)
        end

        it "shows the start date row" do
          expect(rendered_content).to have_css("dt", text: "Start date")
          expect(rendered_content).to have_css("dd", text: training_period.started_on.to_fs(:govuk))
        end

        it "shows the end date row" do
          expect(rendered_content).to have_css("dt", text: "End date")
          expect(rendered_content).to have_css("dd", text: training_period.finished_on.to_fs(:govuk))
        end

        it "shows the API data row" do
          expect(rendered_content).to have_css("dt", text: "API response")
          # expect(rendered_content).to have_css("dd", text: formatted_teacher)
        end
      end

      context "when there is only an expression of interest" do
        let!(:metadata) { FactoryBot.create(:teacher_lead_provider_metadata, :with_latest_ect_training_period, :with_eoi_only) }
        let(:lead_provider_id) { training_period.expression_of_interest_lead_provider.id }

        it "uses the expression of interest lead provider as the title" do
          expect(rendered_content).to have_css(".govuk-summary-card__title", text: training_period.expression_of_interest_lead_provider.name)
        end

        it "shows the lead provider with awaiting confirmation hint text" do
          expect(rendered_content).to have_css("dt", text: "Lead provider")
          expect(rendered_content).to have_css("dd", text: training_period.expression_of_interest_lead_provider.name)
          expect(rendered_content).to have_css("dd .govuk-hint", text: "Awaiting confirmation by #{training_period.expression_of_interest_lead_provider.name}")
        end

        it "shows the placeholder delivery partner text" do
          expect(rendered_content).to have_css("dt", text: "Delivery partner")
          expect(rendered_content).to have_css("dd", text: "No delivery partner confirmed")
        end

        it "falls back to the expression of interest contract period" do
          expect(rendered_content).to have_css("dt", text: "Contract period")
          expect(rendered_content).to have_css("dd", text: training_period.expression_of_interest_contract_period.year)
        end

        it "does not show the API data row" do
          expect(rendered_content).not_to have_css("dt", text: "API response")
        end
      end

      context "when there are multiple training periods" do
        let!(:more_metadata) do
          FactoryBot.create(:training_period, :for_ect, :provider_led, :with_expression_of_interest,
                            started_on: 5.days.ago,
                            ect_at_school_period: training_period.ect_at_school_period)
        end

        it "shows the latest data" do
          expect(teacher.ect_at_school_periods.first.training_periods.count).to eq(2)
          expect(rendered_content).to have_css("dt", text: "API response")
          expect(rendered_content).to include(teacher.trn).once
        end
      end
    end

    context "when the period is for a mentor" do
      let!(:metadata) { FactoryBot.create(:teacher_lead_provider_metadata, :with_latest_mentor_training_period) }
      let(:training_period) { metadata.latest_mentor_training_period }

      before do
        training_period.update!(finished_on: 1.week.ago)
        rendered
      end

      context "when the partnership is confirmed" do
        it "shows the mentor school name in the school row" do
          expect(rendered_content).to have_css("dt", text: "School")
          expect(rendered_content).to have_css("dd", text: training_period.mentor_at_school_period.school.name)
        end

        it "does not show the training programme row" do
          expect(rendered_content).not_to have_css("dt", text: "Training programme")
        end

        it "shows the API data row" do
          expect(rendered_content).to have_css("dt", text: "API response")
          expect(rendered_content).to include("data")
        end
      end

      context "expression of interest" do
        let!(:metadata) { FactoryBot.create(:teacher_lead_provider_metadata, :with_latest_mentor_training_period, :with_eoi_only) }
        let(:lead_provider_id) { training_period.expression_of_interest_lead_provider.id }

        it "uses the expression of interest lead provider as the title" do
          expect(rendered_content).to have_css(".govuk-summary-card__title", text: training_period.expression_of_interest_lead_provider.name)
        end

        it "shows the lead provider with awaiting confirmation hint text" do
          expect(rendered_content).to have_css("dt", text: "Lead provider")
          expect(rendered_content).to have_css("dd", text: training_period.expression_of_interest_lead_provider.name)
          expect(rendered_content).to have_css("dd .govuk-hint", text: "Awaiting confirmation by #{training_period.expression_of_interest_lead_provider.name}")
        end

        it "shows the placeholder delivery partner text" do
          expect(rendered_content).to have_css("dt", text: "Delivery partner")
          expect(rendered_content).to have_css("dd", text: "No delivery partner confirmed")
        end

        it "does not show the API data row" do
          expect(rendered_content).not_to have_css("dt", text: "API response")
        end
      end

      context "when there are multiple training periods" do
        let!(:more_metadata) do
          FactoryBot.create(:training_period, :for_mentor, :provider_led, :with_expression_of_interest,
                            started_on: 5.days.ago,
                            mentor_at_school_period: training_period.mentor_at_school_period)
        end

        it "shows the latest data" do
          expect(teacher.mentor_at_school_periods.first.training_periods.count).to eq(2)
          expect(rendered_content).to have_css("dt", text: "API response")
          expect(rendered_content).to include(teacher.trn).once
        end
      end
    end

    context "when the API raises an error" do
      before do
        allow(API::TeacherSerializer)
        .to receive(:render)
        .and_raise(Enumerable::SoleItemExpectedError)

        rendered
      end

      let(:training_period) { FactoryBot.create(:training_period, :provider_led) }

      it "shows a generic error message" do
        expect(rendered_content).to have_css("dt", text: "API response")
        expect(rendered_content).to have_css("dd", text: "API returned no response")
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
