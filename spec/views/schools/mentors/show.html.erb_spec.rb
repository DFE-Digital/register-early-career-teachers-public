RSpec.describe 'schools/mentors/show.html.erb' do
  let(:programme_type) { 'provider_led' }
  let(:school) { create(:school) }
  let(:mentor_teacher) { create(:teacher, trs_first_name: 'Naruto', trs_last_name: 'Uzumaki') }
  let(:start_date) { Date.new(2023, 9, 1) }
  let(:end_date)   { Date.new(2024, 7, 1) }

  let(:mentor_period) do
    create(:mentor_at_school_period, teacher: mentor_teacher, school:, started_on: start_date, finished_on: end_date)
  end

  let(:ect_teacher) { create(:teacher, trs_first_name: 'Konohamaru', trs_last_name: 'Sarutobi') }

  let(:ect_period) do
    create(:ect_at_school_period, teacher: ect_teacher, school:, started_on: start_date, finished_on: end_date)
  end

  let!(:mentorship_period) do
    create(:mentorship_period, mentor: mentor_period, mentee: ect_period, started_on: start_date, finished_on: end_date)
  end

  before do
    assign(:mentor, mentor_period)
    assign(:teacher, mentor_teacher)
    assign(:ects, [ect_period])
    render
  end

  it 'renders the ECT mentor training details H2' do
    expect(rendered).to have_css('h2.govuk-heading-m', text: 'ECT mentor training details')
  end

  context 'when ECT is provider led' do
    context 'when mentor_completion_date is not present' do
      it 'renders the school summary card' do
        expect(rendered).to have_css('h2.govuk-summary-card__title', text: 'Reported to us by your school')
      end

      it 'renders the lead provider row with the correct label' do
        expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'Lead provider')
      end

      it 'renders the lead provider row with a value' do
        expect(rendered).to have_css('dd.govuk-summary-list__value', text: 'Some value')
      end

      it 'renders the lead provider summary card' do
        expect(rendered).to have_css('h2.govuk-summary-card__title', text: 'Reported to us by your lead provider')
      end

      it 'shows the text that no information has been reported by the lead provider' do
        expect(rendered).to have_text('Your lead provider has not reported any information to us yet')
      end
    end

    context 'when mentor_completion_date is present' do
      let(:mentor_teacher) { create(:teacher, trs_first_name: 'Konohamaru', trs_last_name: 'Sarutobi', mentor_completion_date: Date.new(2025, 4, 9)) }

      it 'does not render the ect teacher cannot do training text' do
        expect(rendered).to have_css('.govuk-body', text: /Konohamaru Sarutobi cannot do ECTE mentor training/)
      end

      it 'does not render the school summary card' do
        expect(rendered).not_to have_css('h2.govuk-summary-card__title', text: 'Reported to us by your school')
      end

      it 'does not render the lead provider row with the correct label' do
        expect(rendered).not_to have_css('dt.govuk-summary-list__key', text: 'Lead provider')
      end

      it 'does not render the lead provider row with a value' do
        expect(rendered).not_to have_css('dd.govuk-summary-list__value', text: 'Some value')
      end

      it 'does not render the lead provider summary card' do
        expect(rendered).not_to have_css('h2.govuk-summary-card__title', text: 'Reported to us by your lead provider')
      end

      it 'does not render the text that no information has been reported by the lead provider' do
        expect(rendered).not_to have_text('Your lead provider has not reported any information to us yet')
      end
    end
  end

  context 'when all ECTs are school-led' do
    let(:ect_period) do
      create(:ect_at_school_period, :school_led, teacher: ect_teacher, school:, started_on: start_date, finished_on: end_date)
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
