RSpec.describe Schools::ECTs::ListingCardComponent, type: :component do
  let(:school) { FactoryBot.create(:school) }
  let(:started_on) { Date.new(2023, 9, 1) }
  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: 'Naruto', trs_last_name: 'Uzumaki') }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:, school:, started_on:, finished_on: nil) }
  let(:training_period) { FactoryBot.create(:training_period, ect_at_school_period:, started_on:) }
  let(:mentor) { FactoryBot.create(:mentor_at_school_period, school:, started_on:, finished_on: nil) }

  context 'when the ECT has a mentor assigned' do
    before do
      FactoryBot.create(:mentorship_period, :ongoing, started_on: ect_at_school_period.started_on, mentee: ect_at_school_period, mentor:)
      render_inline(described_class.new(teacher:, ect_at_school_period:, training_period:))
    end

    it "renders 'Registered' status" do
      expect(rendered_content).to have_selector('.govuk-summary-list__row', text: 'Status')
      expect(rendered_content).to have_text('Registered')
    end
  end

  context 'when the ECT has no mentor assigned' do
    before { render_inline(described_class.new(teacher:, ect_at_school_period:, training_period:)) }

    it "renders 'Mentor required' status" do
      expect(rendered_content).to have_selector('.govuk-summary-list__row', text: 'Status')
      expect(rendered_content).to have_text('Mentor required')
    end
  end

  it "renders the TRN" do
    render_inline(described_class.new(teacher:, ect_at_school_period:, training_period:))

    expect(rendered_content).to have_selector('.govuk-summary-list__row', text: 'TRN')
    expect(rendered_content).to have_text(ect_at_school_period.trn)
  end

  it "renders the school start date" do
    render_inline(described_class.new(teacher:, ect_at_school_period:, training_period:))

    expect(rendered_content).to have_selector(".govuk-summary-list__row", text: "School start date")
    expect(rendered_content).to have_text('1 September 2023')
  end

  it "renders the school reported appropriate body name" do
    render_inline(described_class.new(teacher:, ect_at_school_period:, training_period:))

    expect(rendered_content).to have_selector('.govuk-summary-list__row', text: 'Appropriate body')
    expect(rendered_content).to have_text(ect_at_school_period.school_reported_appropriate_body_name)
  end

  context 'when provider led chosen' do
    let!(:training_period) { FactoryBot.create(:training_period, ect_at_school_period: ect_at_school_period, started_on:) }

    it "renders their latest providers" do
      render_inline(described_class.new(teacher:, ect_at_school_period:, training_period:))

      expect(rendered_content).to have_selector('.govuk-summary-list__row', text: 'Delivery partner')
      expect(rendered_content).to have_text(training_period.delivery_partner_name)

      expect(rendered_content).to have_selector('.govuk-summary-list__row', text: 'Lead provider')
      expect(rendered_content).to have_text(training_period.lead_provider_name)
    end
  end

  context 'when school led chosen' do
    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :school_led, teacher:, school:, started_on:, finished_on: nil) }

    it "don't render providers" do
      render_inline(described_class.new(teacher:, ect_at_school_period:, training_period:))

      expect(rendered_content).not_to have_selector('.govuk-summary-list__row', text: 'Delivery partner')
      expect(rendered_content).not_to have_selector('.govuk-summary-list__row', text: 'Lead provider')
    end
  end

  context 'when latest training period is an expression of interest only' do
    let(:lead_provider) { FactoryBot.create(:lead_provider, name: 'Jimmy Provider') }
    let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:) }
    let(:training_period) do
      FactoryBot.create(
        :training_period,
        :ongoing,
        :with_no_school_partnership,
        ect_at_school_period:,
        started_on:,
        expression_of_interest: active_lead_provider
      )
    end

    it 'renders lead provider name on the EOI' do
      render_inline(described_class.new(teacher:, ect_at_school_period:, training_period:))

      expect(rendered_content).to have_selector('.govuk-summary-list__row', text: 'Lead provider')
      expect(rendered_content).to have_text('Jimmy Provider')
    end

    it 'renders the delivery partner fallback text' do
      render_inline(described_class.new(teacher:, ect_at_school_period:, training_period:))
      expect(rendered_content).to have_selector('.govuk-summary-list__row', text: 'Delivery partner')
      expect(rendered_content).to have_text('Their lead provider will confirm this')
    end
  end
end
