RSpec.describe 'schools/mentors/index.html.erb' do
  let(:school) { FactoryBot.create(:school) }

  before do
    assign(:school, school)
    assign(:mentors, [])
    assign(:number_of_mentors, 0)
    render
  end

  context 'when there are no mentors' do
    it 'shows a message that there are no mentors' do
      expect(rendered).to have_css('div.govuk-grid-column-two-thirds p.govuk-body', text: 'Your school currently has no registered mentors.')
    end

    it 'shows the "assign" link' do
      expect(rendered).to have_css('a.govuk-link', text: 'assign one to an ECT')
    end

    it 'does not render the summary component' do
      expect(rendered).not_to have_css('.govuk-summary-card')
    end

    it 'does not render the search box' do
      expect(rendered).not_to have_css('.govuk-form-group label', text: 'Search by name or teacher reference number (TRN)')
    end
  end

  context 'when there are mentors' do
    let(:teacher) { FactoryBot.create(:teacher, trs_first_name: 'Johnnie', trs_last_name: 'Walker') }
    let(:mentor_period) { FactoryBot.create(:mentor_at_school_period, teacher:, school:) }

    before do
      assign(:school, school)
      assign(:number_of_mentors, 1)
      assign(:filtered_mentors, [teacher])
      assign(:mentor_period_for_school, [mentor_period])
      render
    end

    it 'shows the "assign" link' do
      expect(rendered).to have_css('a.govuk-link', text: 'assign one to an ECT')
    end

    it 'renders the summary component' do
      expect(rendered).to have_css('.govuk-summary-card__title', text: 'Johnnie Walker')
    end

    it 'renders the search box' do
      expect(rendered).to have_css('.govuk-form-group label', text: 'Search by name or teacher reference number (TRN)')
    end

    context 'when the filtered mentors is empty' do
      before do
        assign(:school, school)
        assign(:number_of_mentors, 1)
        assign(:filtered_mentors, [])
        assign(:mentor_period_for_school, [mentor_period])
        render
      end

      it 'renders the no mentors text' do
        expect(rendered).to have_css('.govuk-body', text: 'There are no mentors that match your search.')
      end

      it 'renders the search box' do
        expect(rendered).to have_css('.govuk-form-group label', text: 'Search by name or teacher reference number (TRN)')
      end
    end
  end
end
