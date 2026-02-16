RSpec.describe Schools::ECTs::ListingCardComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:school) { FactoryBot.create(:school) }
  let(:started_on) { Date.new(2023, 9, 1) }
  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki") }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :local_authority_ab, teacher:, school:, started_on:, finished_on: nil) }
  let(:training_period) { FactoryBot.create(:training_period, ect_at_school_period:, started_on:) }
  let(:mentor) { FactoryBot.create(:mentor_at_school_period, school:, started_on:, finished_on: nil) }
  let(:valid_withdrawal_reason) { TrainingPeriod.withdrawal_reasons.keys.first }
  let(:valid_deferral_reason) { TrainingPeriod.deferral_reasons.keys.first }

  context "when the ECT has a mentor assigned" do
    before do
      FactoryBot.create(:mentorship_period, :ongoing, started_on: ect_at_school_period.started_on, mentee: ect_at_school_period, mentor:)
      render_inline(described_class.new(teacher:, ect_at_school_period:, training_period:))
    end

    it "renders 'Registered' status" do
      expect(rendered_content).to have_selector(".govuk-summary-list__row", text: "Status")
      expect(rendered_content).to have_text("Registered")
    end
  end

  context "when the ECT has no mentor assigned" do
    before { render_inline(described_class.new(teacher:, ect_at_school_period:, training_period:)) }

    it "renders action required status with mentor message" do
      expect(rendered_content).to have_selector(".govuk-summary-list__row", text: "Status")
      expect(rendered_content).to have_text("Action required")
      expect(rendered_content).to have_text("A mentor needs to be assigned to Naruto Uzumaki.")
    end
  end

  it "renders the TRN" do
    render_inline(described_class.new(teacher:, ect_at_school_period:, training_period:))

    expect(rendered_content).to have_selector(".govuk-summary-list__row", text: "TRN")
    expect(rendered_content).to have_text(ect_at_school_period.trn)
  end

  it "renders the school start date" do
    render_inline(described_class.new(teacher:, ect_at_school_period:, training_period:))

    expect(rendered_content).to have_selector(".govuk-summary-list__row", text: "School start date")
    expect(rendered_content).to have_text("1 September 2023")
  end

  it "renders the school reported appropriate body name" do
    render_inline(described_class.new(teacher:, ect_at_school_period:, training_period:))

    expect(rendered_content).to have_selector(".govuk-summary-list__row", text: "Appropriate body")
    expect(rendered_content).to have_text(ect_at_school_period.school_reported_appropriate_body_name)
  end

  context "when provider led chosen" do
    let!(:training_period) { FactoryBot.create(:training_period, :ongoing, :provider_led, ect_at_school_period:, started_on:) }

    it "renders their latest providers" do
      render_inline(described_class.new(teacher:, ect_at_school_period:, training_period:))

      expect(rendered_content).to have_selector(".govuk-summary-list__row", text: "Delivery partner")
      expect(rendered_content).to have_text(training_period.delivery_partner_name)

      expect(rendered_content).to have_selector(".govuk-summary-list__row", text: "Lead provider")
      expect(rendered_content).to have_text(training_period.lead_provider_name)
    end
  end

  context "when school led chosen" do
    let(:training_period) { FactoryBot.create(:training_period, :ongoing, :school_led) }

    it "doesn't render providers" do
      render_inline(described_class.new(teacher:, ect_at_school_period:, training_period:))

      expect(rendered_content).not_to have_selector(".govuk-summary-list__row", text: "Delivery partner")
      expect(rendered_content).not_to have_selector(".govuk-summary-list__row", text: "Lead provider")
    end
  end

  context "when latest training period is an expression of interest only" do
    let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Jimmy Provider") }
    let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:) }
    let(:training_period) do
      FactoryBot.create(
        :training_period,
        :ongoing,
        :provider_led,
        :with_only_expression_of_interest,
        ect_at_school_period:,
        started_on:,
        expression_of_interest: active_lead_provider
      )
    end

    it "renders lead provider name on the EOI" do
      render_inline(described_class.new(teacher:, ect_at_school_period:, training_period:))

      expect(rendered_content).to have_selector(".govuk-summary-list__row", text: "Lead provider")
      expect(rendered_content).to have_text("Jimmy Provider")
    end

    it "renders the delivery partner fallback text" do
      render_inline(described_class.new(teacher:, ect_at_school_period:, training_period:))
      expect(rendered_content).to have_selector(".govuk-summary-list__row", text: "Delivery partner")
      expect(rendered_content).to have_text("Their lead provider will confirm this")
    end
  end

  context "when training is withdrawn" do
    let!(:training_period) { FactoryBot.create(:training_period, :ongoing, :provider_led, ect_at_school_period:, started_on:) }

    before do
      training_period.update!(
        withdrawn_at: Time.zone.today,
        withdrawal_reason: valid_withdrawal_reason
      )
      render_inline(described_class.new(teacher:, ect_at_school_period:, training_period:, current_school: school))
    end

    it "renders the withdrawn warning link" do
      expect(rendered_content).to have_link(
        "continuing their training or if they have left your school.",
        href: "/school/ects/#{ect_at_school_period.id}#training-details"
      )

      expect(rendered_content).to include("Tell us if Naruto Uzumaki will be")
    end

    it "renders action required withdrawn status message" do
      expect(rendered_content).to have_text("Action required")
      expect(rendered_content).to match(
        /(have|has) told us that Naruto Uzumaki is no longer training with them\. Contact them if you think this is an error\./
      )
    end

    it "does not render lead provider or delivery partner rows" do
      expect(rendered_content).not_to have_selector(".govuk-summary-list__row", text: "Lead provider")
      expect(rendered_content).not_to have_selector(".govuk-summary-list__row", text: "Delivery partner")
    end
  end

  context "when training is withdrawn and the ECT has no mentor assigned" do
    let!(:training_period) { FactoryBot.create(:training_period, :ongoing, :provider_led, ect_at_school_period:, started_on:) }

    before do
      training_period.update!(
        withdrawn_at: Time.zone.today,
        withdrawal_reason: valid_withdrawal_reason
      )

      render_inline(described_class.new(teacher:, ect_at_school_period:, training_period:, current_school: school))
    end

    it "shows withdrawn action required instead of mentor required" do
      expect(rendered_content).to have_text("Action required")
      expect(rendered_content).to match(/no longer training with them/i)

      expect(rendered_content).not_to have_text("Mentor required")
      expect(rendered_content).not_to have_text("A mentor needs to be assigned")
    end
  end

  context "when training is deferred and the ECT has no mentor assigned" do
    let!(:training_period) { FactoryBot.create(:training_period, :ongoing, :provider_led, ect_at_school_period:, started_on:) }

    before do
      training_period.update!(
        deferred_at: Time.zone.today,
        deferral_reason: valid_deferral_reason
      )

      render_inline(described_class.new(teacher:, ect_at_school_period:, training_period:, current_school: school))
    end

    it "shows training paused instead of mentor required" do
      expect(rendered_content).to have_text("Training paused")
      expect(rendered_content).to match(/training is paused/i)

      expect(rendered_content).not_to have_text("Mentor required")
      expect(rendered_content).not_to have_text("A mentor needs to be assigned")
    end
  end

  context "when training is deferred" do
    let!(:training_period) { FactoryBot.create(:training_period, :ongoing, :provider_led, ect_at_school_period:, started_on:) }

    before do
      training_period.update!(
        deferred_at: Time.zone.today,
        deferral_reason: valid_deferral_reason
      )
      render_inline(described_class.new(teacher:, ect_at_school_period:, training_period:))
    end

    it "renders training paused status message" do
      expect(rendered_content).to have_text("Training paused")
      expect(rendered_content).to have_text("Contact them if you think this is an error.")
    end

    it "still renders lead provider and delivery partner rows" do
      expect(rendered_content).to have_selector(".govuk-summary-list__row", text: "Lead provider")
      expect(rendered_content).to have_text(training_period.lead_provider_name)

      expect(rendered_content).to have_selector(".govuk-summary-list__row", text: "Delivery partner")
      expect(rendered_content).to have_text(training_period.delivery_partner_name)
    end
  end

  context "when the ECT is reported as leaving by the current school" do
    before do
      ect_at_school_period.update!(finished_on: Time.zone.today + 1.day, reported_leaving_by_school_id: school.id)
    end

    it "shows the leaving status when current_school is provided" do
      render_inline(described_class.new(teacher:, ect_at_school_period:, training_period:, current_school: school))

      expect(rendered_content).to have_css("strong.govuk-tag.govuk-tag--yellow", text: "Leaving school")
    end

    it "does not show the leaving status when current_school is not provided" do
      render_inline(described_class.new(teacher:, ect_at_school_period:, training_period:))

      expect(rendered_content).not_to have_css("strong.govuk-tag.govuk-tag--yellow", text: "Leaving school")
    end
  end
end
