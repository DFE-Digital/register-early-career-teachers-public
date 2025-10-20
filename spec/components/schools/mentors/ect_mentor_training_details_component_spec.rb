RSpec.describe Schools::Mentors::ECTMentorTrainingDetailsComponent, type: :component do
  include TeacherHelper

  let(:school) { FactoryBot.create(:school) }
  let(:mentor_start_date) { Date.new(2023, 1, 1) }

  let(:teacher) { FactoryBot.create(:teacher, mentor_became_ineligible_for_funding_on: nil, mentor_became_ineligible_for_funding_reason: nil) }
  let(:mentor) { FactoryBot.create(:mentor_at_school_period, teacher:, school:, started_on: mentor_start_date, finished_on: nil) }

  let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Hidden leaf village") }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:, school:) }

  describe "rendering based on mentor training state" do
    context "when registered via EOI (awaiting confirmation)" do
      before do
        FactoryBot.create(
          :training_period, :provider_led, :for_mentor,
          mentor_at_school_period: mentor,
          started_on: mentor_start_date,
          finished_on: nil,
          school_partnership: nil,
          expression_of_interest: active_lead_provider
        )
      end

      it "shows the LP and 'Awaiting confirmation' hint and DP 'Yet to be reported'" do
        render_inline(described_class.new(teacher:, mentor:))

        expect(rendered_content).to have_css("h2.govuk-heading-m", text: "ECTE mentor training details")
        expect(rendered_content).to have_css("dt.govuk-summary-list__key", text: "Lead provider")
        expect(rendered_content).to have_text("Hidden leaf village")
        expect(rendered_content).to have_css(".govuk-hint", text: /Awaiting confirmation by Hidden leaf village/)

        expect(rendered_content).to have_css("dt.govuk-summary-list__key", text: "Delivery partner")
        expect(rendered_content).to have_text("Yet to be reported by the lead provider")
      end
    end

    context "when partnership is confirmed" do
      before do
        FactoryBot.create(
          :training_period, :provider_led, :for_mentor,
          mentor_at_school_period: mentor,
          started_on: mentor_start_date,
          finished_on: nil,
          school_partnership:
        )
      end

      it "shows 'Confirmed by' hint and delivery partner + change-DP hint" do
        render_inline(described_class.new(teacher:, mentor:))

        expect(rendered_content).to have_css(".govuk-hint", text: /Confirmed by Hidden leaf village/)
        expect(rendered_content).to have_css("dt.govuk-summary-list__key", text: "Delivery partner")
        expect(rendered_content).to have_text(lead_provider_delivery_partnership.delivery_partner.name)
        expect(rendered_content).to have_css(".govuk-hint", text: /To change the delivery partner, you must contact the lead provider/)
      end
    end

    context "when the only mentor training period is in the past" do
      before do
        FactoryBot.create(
          :training_period, :provider_led, :for_mentor,
          mentor_at_school_period: mentor,
          started_on: mentor_start_date + 1.month, # 2023-02-01
          finished_on: mentor_start_date + 3.months, # 2023-04-01
          school_partnership:
        )
      end

      it "does not render (scope is current_or_future)" do
        component = described_class.new(teacher:, mentor:)
        expect(component.render?).to be(false)

        render_inline(component)
        expect(rendered_content).to be_empty
      end
    end

    context "when mentor has a future provider-led period" do
      before do
        FactoryBot.create(
          :training_period, :provider_led, :for_mentor,
          mentor_at_school_period: mentor,
          started_on: mentor_start_date + 2.months,
          finished_on: nil,
          school_partnership:
        )
      end

      it "renders the details (current_or_future includes future)" do
        component = described_class.new(teacher:, mentor:)
        expect(component.render?).to be(true)

        render_inline(component)
        expect(rendered_content).to have_text("Lead provider")
      end
    end
  end

  describe "ineligibility states" do
    context "when ineligible because completed (completed_declaration_received)" do
      let(:date) { Date.new(2024, 1, 1) }

      before do
        teacher.update!(
          mentor_became_ineligible_for_funding_on: date,
          mentor_became_ineligible_for_funding_reason: "completed_declaration_received"
        )
      end

      it "shows the completed line with GOV.UK date and no summary list" do
        render_inline(described_class.new(teacher:, mentor:))

        expect(rendered_content).to have_css(".govuk-body", text: "#{teacher_full_name(teacher)} completed mentor training on #{date.to_fs(:govuk)}.")
      end
    end

    context "when ineligible because completed during early roll out" do
      let(:date) { Date.new(2024, 2, 1) }

      before do
        teacher.update!(
          mentor_became_ineligible_for_funding_on: date,
          mentor_became_ineligible_for_funding_reason: "completed_during_early_roll_out"
        )
      end

      it "shows the completed copy with the correct date" do
        render_inline(described_class.new(teacher:, mentor:))
        expect(rendered_content).to have_text("completed mentor training on #{date.to_fs(:govuk)}")
      end
    end

    context "when ineligible because started but not completed" do
      before do
        teacher.update!(
          mentor_became_ineligible_for_funding_on: Date.new(2024, 1, 1),
          mentor_became_ineligible_for_funding_reason: "started_not_completed"
        )
      end

      it "shows the correct paragraph and hides lists" do
        render_inline(described_class.new(teacher:, mentor:))

        expect(rendered_content).to have_css(".govuk-body", text: /cannot do further mentor training/i)
        expect(rendered_content).to have_text("lead provider")
      end
    end

    context "when ineligible but also has a current training period" do
      before do
        teacher.update!(
          mentor_became_ineligible_for_funding_on: Date.new(2024, 1, 1),
          mentor_became_ineligible_for_funding_reason: "completed_declaration_received"
        )
        FactoryBot.create(
          :training_period, :provider_led, :for_mentor,
          mentor_at_school_period: mentor,
          started_on: mentor_start_date,
          finished_on: nil,
          school_partnership:
        )
      end

      it "prefers the ineligible branch and does not render the summary list" do
        render_inline(described_class.new(teacher:, mentor:))

        expect(rendered_content).to have_text("completed mentor training on 1 January 2024")
        expect(rendered_content).not_to have_text("Lead provider")
      end
    end
  end

  describe "when nothing should render" do
    context "when no mentor training period and not ineligible" do
      it "does not render (no heading)" do
        component = described_class.new(teacher:, mentor:)
        expect(component.render?).to be(false)

        render_inline(component)
        expect(rendered_content).not_to have_css("h2", text: "ECTE mentor training details")
        expect(rendered_content).to be_empty
      end
    end
  end
end
