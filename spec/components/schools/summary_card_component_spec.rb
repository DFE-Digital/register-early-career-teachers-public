RSpec.describe Schools::SummaryCardComponent, type: :component do
  let(:school_reported_appropriate_body) { FactoryBot.create(:appropriate_body, name: 'an org that assures the quality of statutory teacher induction') }
  let(:lead_provider) { FactoryBot.create(:lead_provider, name: 'An org that designs the training') }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner, name: 'An org that delivers the training') }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:) }

  let(:school_led_ect_at_school_period) do
    FactoryBot.create(:ect_at_school_period, :ongoing, school_reported_appropriate_body:)
  end

  let(:school_led_training_period) { FactoryBot.create(:training_period, :ongoing, ect_at_school_period: school_led_ect_at_school_period) }

  let(:provider_led_ect_at_school_period) do
    FactoryBot.create(:ect_at_school_period,
                      :ongoing,
                      school_reported_appropriate_body:,
                      started_on: '2021-01-01')
  end

  let(:provider_led_training_period) { FactoryBot.create(:training_period, :provider_led, :ongoing, school_partnership:) }

  context 'when data is reported by the school' do
    before { render_inline(described_class.new(title: 'Reported to us by your school', ect_at_school_period: school_led_ect_at_school_period, training_period: school_led_training_period, data_source: :school)) }

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

    it 'renders the training programme' do
      within page.find(".govuk-summary-list__row", text: "Training programme") do
        expect(page).to have_text("School-led")
      end
    end

    it 'does not render the lead provider' do
      expect(page).not_to have_selector(".govuk-summary-list__row", text: "Lead provider")
    end

    context "when the ECT is provider-led and reported by the school" do
      before { render_inline(described_class.new(title: "Reported to us by your school", ect_at_school_period: provider_led_ect_at_school_period, training_period: provider_led_training_period, data_source: :school)) }

      it "renders the lead provider" do
        within page.find(".govuk-summary-list__row", text: "Lead provider") do
          expect(page).to have_text("An org that designs the training")
        end
      end
    end
  end

  context 'when data is reported by the lead provider' do
    before { render_inline(described_class.new(title: 'Reported to us by your lead provider', ect_at_school_period: provider_led_ect_at_school_period, training_period: provider_led_training_period, data_source: :lead_provider)) }

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
    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, school_reported_appropriate_body:) }
    let(:training_period) { FactoryBot.create(:training_period, :ongoing, :school_led) }

    before do
      FactoryBot.create(:induction_period, teacher: ect_at_school_period.teacher, started_on: '2023-01-01')
      render_inline(described_class.new(title: 'Reported to us by your appropriate body',
                                        ect_at_school_period:,
                                        training_period:,
                                        data_source: :appropriate_body))
    end

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

    it 'renders the training programme' do
      within page.find(".govuk-summary-list__row", text: "Training programme") do
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
    before do
      render_inline(described_class.new(title: 'Reported to us by your appropriate body',
                                        ect_at_school_period: school_led_ect_at_school_period,
                                        training_period: school_led_training_period,
                                        data_source: :appropriate_body))
    end

    it 'renders a message indicating no information is available' do
      expect(page).to have_text('Your appropriate body has not reported any information to us yet.')
    end

    it 'does not render an empty key column' do
      expect(page).not_to have_selector('.govuk-summary-list__key:empty')
    end
  end

  context 'when no training periods exist for a provider-led ECT' do
    let(:provider_led_ect_at_school_period_without_training_periods) do
      FactoryBot.create(:ect_at_school_period, :ongoing, school_reported_appropriate_body:)
    end

    before do
      render_inline(
        described_class.new(
          title: 'Reported to us by your lead provider',
          ect_at_school_period: provider_led_ect_at_school_period_without_training_periods,
          training_period: nil,
          data_source: :lead_provider
        )
      )
    end

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
