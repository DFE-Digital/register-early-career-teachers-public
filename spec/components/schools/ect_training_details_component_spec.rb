RSpec.describe Schools::ECTTrainingDetailsComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Ambition Institute") }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner, name: "Test Delivery Partner") }
  let(:active_lead_provider) { FactoryBot.build(:active_lead_provider, lead_provider:) }
  let(:lead_provider_delivery_partnership) { FactoryBot.build(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
  let(:school_partnership) { FactoryBot.build(:school_partnership, lead_provider_delivery_partnership:, school: ect_at_school_period.school) }
  let(:teacher) { FactoryBot.create(:teacher, trn: "9876543", trs_first_name: "John", trs_last_name: "Doe") }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:) }
  let(:training_period) { FactoryBot.build(:training_period, ect_at_school_period:, school_partnership:) }

  let(:component) { described_class.new(ect_at_school_period:, training_period:) }

  before { render_inline(component) }

  it "renders the section heading" do
    expect(page).to have_selector("h2.govuk-heading-m", text: "Training details")
  end

  it "renders the training programme row" do
    expect(page).to have_summary_list_row("Training programme")
  end

  context "when there is no training period" do
    let(:training_period) { nil }
    let(:component) { described_class.new(ect_at_school_period:, training_period:) }

    it "renders nothing" do
      render_inline(component)
      expect(page).to have_no_selector("h2", text: "Training details")
      expect(page).to have_no_selector(".govuk-summary-list")
    end
  end

  context "when provider-led training" do
    let(:training_period) { FactoryBot.build(:training_period, :provider_led, ect_at_school_period:) }

    it "shows lead provider information" do
      expect(page).to have_summary_list_row(
        "Lead provider",
        value: "Not available"
      )
    end

    it "shows delivery partner information" do
      expect(page).to have_summary_list_row(
        "Delivery partner",
        value: "Yet to be reported by the lead provider"
      )
    end

    context "with confirmed partnership" do
      it "shows lead provider information" do
        expect(page).to have_summary_list_row(
          "Lead provider",
          value: "Not available"
        )
      end

      it "shows delivery partner information" do
        expect(page).to have_summary_list_row(
          "Delivery partner",
          value: "Yet to be reported by the lead provider"
        )
      end
    end

    context "with expression of interest only" do
      let(:training_period) do
        FactoryBot.create(:training_period, :provider_led, ect_at_school_period:, started_on: ect_at_school_period.started_on, finished_on: ect_at_school_period.finished_on) do |tp|
          tp.school_partnership = nil
          tp.expression_of_interest = FactoryBot.create(:active_lead_provider)
        end
      end

      it "shows lead provider information with awaiting confirmation status" do
        expect(page).to have_summary_list_row("Lead provider")
        expect(page).to have_text("Awaiting confirmation by")
      end

      it "shows delivery partner information" do
        expect(page).to have_summary_list_row(
          "Delivery partner",
          value: "Yet to be reported by the lead provider"
        )
      end
    end
  end

  context "when school-led training" do
    let(:training_period) { FactoryBot.build(:training_period, :school_led, ect_at_school_period:) }

    it "does not show lead provider information" do
      expect(page).not_to have_summary_list_row("Lead provider")
    end

    it "does not show delivery partner information" do
      expect(page).not_to have_summary_list_row("Delivery partner")
    end
  end

  context "when training is withdrawn" do
    let(:training_period) do
      FactoryBot.create(
        :training_period,
        :provider_led,
        ect_at_school_period:,
        started_on: 1.year.ago.to_date,
        finished_on: nil,
        withdrawn_at: Time.zone.today,
        withdrawal_reason: TrainingPeriod.withdrawal_reasons.keys.first
      )
    end

    it "shows the action required tag and withdrawn message" do
      expect(page).to have_text("is no longer training with them")
    end

    it "shows a link to select a lead provider" do
      expect(page).to have_link("select a lead provider")
    end

    it "shows a link to change programme type to school-led" do
      expect(page).to have_link("changing their programme type to school-led")
    end

    it "does not render the normal summary list" do
      expect(page).to have_no_css(".govuk-summary-list")
      expect(page).not_to have_text("Training programme")
      expect(page).not_to have_text("Lead provider")
      expect(page).not_to have_text("Delivery partner")
    end
  end

  context "when training is deferred" do
    let(:training_period) do
      FactoryBot.create(
        :training_period,
        :provider_led,
        ect_at_school_period:,
        started_on: ect_at_school_period.started_on,
        finished_on: nil,
        deferred_at: Time.zone.today,
        deferral_reason: TrainingPeriod.deferral_reasons.keys.first
      )
    end

    it "renders the normal training details summary list" do
      expect(page).to have_css(".govuk-summary-list")
    end

    it "shows the training programme row" do
      expect(page).to have_summary_list_row("Training programme")
    end

    it "still shows lead provider and delivery partner rows" do
      expect(page).to have_summary_list_row("Lead provider")
      expect(page).to have_summary_list_row("Delivery partner")
    end
  end

  describe "#lead_provider_display_text" do
    context "with confirmed partnership" do
      let(:training_period) { FactoryBot.create(:training_period, :provider_led, :with_school_partnership, ect_at_school_period:, started_on: ect_at_school_period.started_on, finished_on: ect_at_school_period.finished_on) }

      it "shows confirmed status" do
        expect(component.send(:lead_provider_display_text)).to include("Confirmed by")
      end
    end

    context "with only expression of interest" do
      let(:training_period) do
        FactoryBot.create(:training_period, :provider_led, ect_at_school_period:, started_on: ect_at_school_period.started_on, finished_on: ect_at_school_period.finished_on) do |tp|
          tp.school_partnership = nil
          tp.expression_of_interest = FactoryBot.create(:active_lead_provider)
        end
      end

      it "shows awaiting confirmation status" do
        expect(component.send(:lead_provider_display_text)).to include("Awaiting confirmation by")
      end

      it "calls only_expression_of_interest? method on training_period" do
        allow(training_period).to receive(:only_expression_of_interest?).and_return(true)
        expect(training_period).to receive(:only_expression_of_interest?)
        component.send(:lead_provider_display_text)
      end
    end

    context "with no partnership or expression of interest" do
      let(:training_period) do
        FactoryBot.create(:training_period, :provider_led, ect_at_school_period:, started_on: ect_at_school_period.started_on, finished_on: ect_at_school_period.finished_on) do |tp|
          tp.school_partnership = nil
          tp.expression_of_interest = nil
        end
      end

      it "returns fallback lead provider name" do
        expect(component.send(:lead_provider_display_text)).to eq("Not available")
      end
    end
  end

  describe "#training_programme_display_name" do
    context "when training programme is provider_led" do
      let(:training_period) { FactoryBot.build(:training_period, :provider_led, ect_at_school_period:) }

      it "displays Provider-led" do
        expect(page).to have_summary_list_row(
          "Training programme",
          value: "Provider-led"
        )
      end
    end

    context "when training programme is school_led" do
      let(:training_period) { FactoryBot.build(:training_period, :school_led, ect_at_school_period:) }

      it "displays School-led" do
        expect(page).to have_summary_list_row(
          "Training programme",
          value: "School-led"
        )
      end
    end

    context "when training programme is nil" do
      let(:training_period) { FactoryBot.build(:training_period, ect_at_school_period:, training_programme: nil) }

      it "displays Unknown" do
        expect(page).to have_summary_list_row(
          "Training programme",
          value: "Unknown"
        )
      end
    end
  end
end
