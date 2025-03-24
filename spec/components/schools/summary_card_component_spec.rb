require "rails_helper"

RSpec.describe Schools::SummaryCardComponent, type: :component do
  let(:appropriate_body) { FactoryBot.create(:appropriate_body, name: 'an org that assures the quality of statutory teacher induction') }
  let(:lead_provider) { FactoryBot.create(:lead_provider, name: 'An org that designs the training') }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner, name: 'An org that delivers the training') }
  let(:provider_partnership) { FactoryBot.create(:provider_partnership, lead_provider:, delivery_partner:) }

  let(:school_led_ect) do
    FactoryBot.create(:ect_at_school_period, :active, :school_led, appropriate_body:)
  end

  let(:provider_led_ect) { FactoryBot.create(:ect_at_school_period, :active, :provider_led, appropriate_body:, lead_provider:, started_on: '2021-01-01') }

  let!(:training_period) { FactoryBot.create(:training_period, ect_at_school_period: provider_led_ect, provider_partnership:, started_on: '2022-01-01', finished_on: '2022-06-01') }

  context 'when data is reported by the school' do
    before { render_inline(described_class.new(title: 'Reported to us by your school', ect: school_led_ect, data_source: :school)) }

    it 'renders the summary card' do
      expect(page).to have_selector(".govuk-summary-card")
    end

    it 'renders the correct title' do
      expect(page).to have_selector(".govuk-summary-card__title", text: "Reported to us by your school")
    end

    it 'renders the appropriate body' do
      within page.find(".govuk-summary-list__row", text: "Appropriate body") do
        expect(page).to have_text('an org that assures the quality of statutory teacher induction')
      end
    end

    it 'renders the programme type' do
      within page.find(".govuk-summary-list__row", text: "Programme type") do
        expect(page).to have_text("School-led")
      end
    end

    it 'does not render the lead provider' do
      expect(page).not_to have_selector(".govuk-summary-list__row", text: "Lead provider")
    end

    context "when the ECT is provider-led and reported by the school" do
      let(:ect) { provider_led_ect }

      before { render_inline(described_class.new(title: "Reported to us by your school", ect:, data_source: :school)) }

      it "renders the lead provider" do
        within page.find(".govuk-summary-list__row", text: "Lead provider") do
          expect(page).to have_text("An org that designs the training")
        end
      end
    end
  end

  context 'when data is reported by the lead provider' do
    before { render_inline(described_class.new(title: 'Reported to us by your lead provider', ect: provider_led_ect, data_source: :lead_provider)) }

    it 'renders the summary card' do
      expect(page).to have_selector(".govuk-summary-card")
    end

    it 'renders the correct title' do
      expect(page).to have_selector(".govuk-summary-card__title", text: "Reported to us by your lead provider")
    end

    it 'renders the lead provider' do
      within page.find(".govuk-summary-list__row", text: "Lead provider") do
        expect(page).to have_text("An org that designs the training")
      end
    end

    it 'renders the delivery partner' do
      within page.find(".govuk-summary-list__row", text: "Delivery partner") do
        expect(page).to have_text("An org that delivers the training")
      end
    end
  end

  context 'when data is reported by the appropriate body' do
    let(:school_led_ect_with_induction) do
      ect = FactoryBot.create(:ect_at_school_period, :active, :school_led, appropriate_body:)
      FactoryBot.create(:induction_period, teacher: ect.teacher, started_on: '2023-01-01')
      ect
    end

    before { render_inline(described_class.new(title: 'Reported to us by your appropriate body', ect: school_led_ect_with_induction, data_source: :appropriate_body)) }

    it 'renders the summary card' do
      expect(page).to have_selector(".govuk-summary-card")
    end

    it 'renders the correct title' do
      expect(page).to have_selector(".govuk-summary-card__title", text: "Reported to us by your appropriate body")
    end

    it 'renders the appropriate body' do
      within page.find(".govuk-summary-list__row", text: "Appropriate body") do
        expect(page).to have_text("an org that assures the quality of statutory teacher induction")
      end
    end

    it 'renders the programme type' do
      within page.find(".govuk-summary-list__row", text: "Programme type") do
        expect(page).to have_text("School-led")
      end
    end

    it 'renders the induction start date' do
      within page.find(".govuk-summary-list__row", text: "Induction start date") do
        expect(page).to have_text("1 January 2023")
      end
    end
  end

  context 'when no data is available' do
    before { render_inline(described_class.new(title: 'Reported to us by your appropriate body', ect: school_led_ect, data_source: :appropriate_body)) }

    it 'renders a message indicating no information is available' do
      expect(page).to have_text('Your appropriate body has not reported any information to us yet.')
    end

    it 'does not render an empty key column' do
      expect(page).not_to have_selector('.govuk-summary-list__key:empty')
    end
  end

  context 'when no training periods exist for a provider-led ECT' do
    let(:provider_led_ect_without_training_periods) do
      FactoryBot.create(:ect_at_school_period, :active, :provider_led, appropriate_body:, lead_provider:)
    end

    before { render_inline(described_class.new(title: 'Reported to us by your lead provider', ect: provider_led_ect_without_training_periods, data_source: :lead_provider)) }

    it 'renders a message indicating no information is available' do
      within page.find(".govuk-summary-card", text: "Reported to us by your lead provider") do
        expect(page).to have_text('Your lead provider has not reported any information to us yet.')
      end
    end

    it 'does not render any summary list rows' do
      within page.find(".govuk-summary-card", text: "Reported to us by your lead provider") do
        expect(page).not_to have_selector(".govuk-summary-list__row")
      end
    end
  end
end
