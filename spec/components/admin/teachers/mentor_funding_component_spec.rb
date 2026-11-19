RSpec.describe Admin::Teachers::MentorFundingComponent, type: :component do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(teacher:) }

  context "when the mentor is not yet eligible for funded training" do
    let(:teacher) { FactoryBot.create(:teacher) }

    it "shows why the mentor is not yet eligible for funded training" do
      expect(rendered).to have_css(".govuk-summary-card__title", text: "Mentor training summary")
      expect(rendered.text.squish).to include(
        "Not eligible for funded training yet. They have not been assigned an ECT on provider-led training."
      )
    end
  end

  context "when the mentor is eligible for funding" do
    let(:teacher) { FactoryBot.create(:teacher, mentor_first_became_eligible_for_training_at: Time.zone.now) }

    it "shows eligible funding details" do
      expect(rendered).to have_css(".govuk-summary-card__title", text: "Mentor training summary")
      expect(rendered.text.squish).to include("Training not completed yet. Eligible for funded training.")
    end
  end

  context "when the mentor became ineligible for funding" do
    context "when the mentor became ineligible due to a completed declaration" do
      let(:teacher) do
        FactoryBot.create(:teacher,
                          mentor_first_became_eligible_for_training_at: Date.new(2026, 1, 1),
                          mentor_became_ineligible_for_funding_on:,
                          mentor_became_ineligible_for_funding_reason: "completed_declaration_received")
      end

      context "when the mentor completed training in the past" do
        let(:mentor_became_ineligible_for_funding_on) { Date.new(2026, 8, 12) }

        it "shows completed training and the funding end date when a lead provider submitted a completed declaration" do
          expect(rendered).to have_css(".govuk-summary-card__title", text: "Mentor training summary")
          expect(rendered.text.squish).to include(
            "A lead provider submitted a completed declaration. Funding ended on 12 August 2026."
          )
        end
      end

      context "when the mentor completed training today" do
        let(:mentor_became_ineligible_for_funding_on) { Time.zone.today }

        it "shows completed training and the funding end date when a lead provider submitted a completed declaration" do
          expect(rendered).to have_css(".govuk-summary-card__title", text: "Mentor training summary")
          expect(rendered.text.squish).to include(
            "A lead provider submitted a completed declaration. Funding ended on #{Time.zone.today.to_fs(:govuk)}."
          )
        end
      end

      context "when the mentor completed training in the future" do
        let(:mentor_became_ineligible_for_funding_on) { 1.day.from_now }

        it "shows completed training and the funding end date when a lead provider submitted a completed declaration" do
          expect(rendered).to have_css(".govuk-summary-card__title", text: "Mentor training summary")
          expect(rendered.text.squish).to include("Training not completed yet. Eligible for funded training.")
        end
      end
    end

    context "when the mentor completed training during early roll-out" do
      let(:teacher) do
        FactoryBot.create(:teacher,
                          mentor_became_ineligible_for_funding_on: Date.new(2021, 4, 19),
                          mentor_became_ineligible_for_funding_reason: "completed_during_early_roll_out")
      end

      it "shows completed training during early roll-out and the early funding end date" do
        expect(rendered).to have_css(".govuk-summary-card__title", text: "Mentor training summary")
        expect(rendered.text.squish).to include("Completed during early roll-out. Funding ended on 19 April 2021.")
      end
    end

    context "when the mentor did not complete training" do
      let(:teacher) do
        FactoryBot.create(:teacher,
                          mentor_first_became_eligible_for_training_at: Date.new(2026, 1, 1),
                          mentor_became_ineligible_for_funding_on:,
                          mentor_became_ineligible_for_funding_reason: "started_not_completed")
      end

      context "when reason was recorded in the past" do
        let(:mentor_became_ineligible_for_funding_on) { Date.new(2026, 8, 12) }

        it "shows incomplete training and the funding end date when training was started but not completed" do
          expect(rendered).to have_css(".govuk-summary-card__title", text: "Mentor training summary")
          expect(rendered.text.squish).to include(
            "Did not finish training within the funded period. Funding ended on 12 August 2026."
          )
        end
      end

      context "when the reason was recorded today" do
        let(:mentor_became_ineligible_for_funding_on) { Time.zone.today }

        it "shows incomplete training and the funding end date when training was started but not completed" do
          expect(rendered).to have_css(".govuk-summary-card__title", text: "Mentor training summary")
          expect(rendered.text.squish).to include(
            "Did not finish training within the funded period. Funding ended on #{Time.zone.today.to_fs(:govuk)}."
          )
        end
      end

      context "when reason was recorded in the future" do
        let(:mentor_became_ineligible_for_funding_on) { 1.day.from_now }

        it "shows incomplete training and the funding end date when training was started but not completed" do
          expect(rendered).to have_css(".govuk-summary-card__title", text: "Mentor training summary")
          expect(rendered.text.squish).to include("Training not completed yet. Eligible for funded training.")
        end
      end
    end
  end
end
