RSpec.describe 'schools/mentors/show.html.erb' do
  let(:school) { FactoryBot.create(:school) }
  let(:start_date) { Date.new(2023, 9, 1) }

  let(:mentor_teacher) do
    FactoryBot.create(:teacher, trs_first_name: 'Naruto', trs_last_name: 'Uzumaki', mentor_became_ineligible_for_funding_on:, mentor_became_ineligible_for_funding_reason:)
  end

  let(:mentor_became_ineligible_for_funding_on) { nil }
  let(:mentor_became_ineligible_for_funding_reason) { nil }

  let(:mentor_period) do
    FactoryBot.create(:mentor_at_school_period, teacher: mentor_teacher, school:, started_on: start_date, finished_on: nil)
  end

  let(:lead_provider) { FactoryBot.create(:lead_provider, name: 'Hidden leaf village') }

  let(:ect_teacher) do
    FactoryBot.create(:teacher, trs_first_name: 'Konohamaru', trs_last_name: 'Sarutobi')
  end

  let(:ect_period) do
    FactoryBot.create(
      :ect_at_school_period,
      teacher: ect_teacher,
      school:,
      started_on: start_date,
      finished_on: nil,
      lead_provider:,
      programme_type: 'provider_led'
    )
  end

  let!(:mentorship_period) do
    FactoryBot.create(:mentorship_period, mentor: mentor_period, mentee: ect_period, started_on: start_date, finished_on: nil)
  end

  before do
    assign(:mentor, mentor_period)
    assign(:teacher, mentor_teacher)
    assign(:ects, mentor_period.currently_assigned_ects)
    render
  end

  context 'when mentor is eligible (no completion date)' do
    it 'renders the ECT mentor training details H2' do
      expect(rendered).to have_css('h2.govuk-heading-m', text: 'ECTE mentor training details')
    end

    it 'renders the school summary card' do
      expect(rendered).to have_css('h2.govuk-summary-card__title', text: 'Reported to us by your school')
    end

    it 'renders the lead provider row with the correct label' do
      expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'Lead provider')
    end

    it 'renders the lead provider row with a value' do
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: 'Hidden leaf village')
    end

    it 'renders the lead provider summary card' do
      expect(rendered).to have_css('h2.govuk-summary-card__title', text: 'Reported to us by your lead provider')
    end

    it 'shows the text that no information has been reported by the lead provider' do
      expect(rendered).to have_text('Your lead provider has not reported any information to us yet')
    end
  end

  context 'when mentor is not eligible (i.e has a `mentor_became_ineligible_for_funding_on` date)' do
    let(:mentor_became_ineligible_for_funding_on) { Date.new(2024, 1, 1) }
    let(:mentor_became_ineligible_for_funding_reason) { 'completed_declaration_received' }

    it 'renders the ineligible message' do
      expect(rendered).to have_css('.govuk-body', text: /Naruto Uzumaki cannot do ECTE mentor training/)
    end

    it 'does not render the school summary card' do
      expect(rendered).not_to have_css('h2.govuk-summary-card__title', text: 'Reported to us by your school')
    end

    it 'does not render the lead provider summary card' do
      expect(rendered).not_to have_css('h2.govuk-summary-card__title', text: 'Reported to us by your lead provider')
    end

    it 'does not render the lead provider row with the correct label' do
      expect(rendered).not_to have_css('dt.govuk-summary-list__key', text: 'Lead provider')
    end

    it 'does not render the lead provider row with a value' do
      expect(rendered).not_to have_css('dd.govuk-summary-list__value', text: 'Hidden leaf village')
    end

    it 'does not show the no info text' do
      expect(rendered).not_to have_text('Your lead provider has not reported any information to us yet')
    end
  end

  context 'when all ECTs are school-led' do
    let(:ect_period) do
      FactoryBot.create(:ect_at_school_period, :school_led, teacher: ect_teacher, school:, started_on: start_date, finished_on: nil)
    end

    before do
      assign(:mentor, mentor_period)
      assign(:teacher, mentor_teacher)
      assign(:ects, mentor_period.currently_assigned_ects)
      render
    end

    it 'does not render the ECT mentor training details H2' do
      expect(rendered).not_to have_css('h2.govuk-heading-m', text: 'ECT mentor training details')
    end

    it 'does not render the school summary card' do
      expect(rendered).not_to have_css('h2.govuk-summary-card__title', text: 'Reported to us by your school')
    end

    it 'does not render the lead provider row' do
      expect(rendered).not_to have_css('dt.govuk-summary-list__key', text: 'Lead provider')
    end
  end
end
