RSpec.describe 'schools/ects/index.html.erb' do
  let(:school) { FactoryBot.create(:school) }

  before do
    assign(:filtered_teachers, [])
    assign(:ects, [])
    assign(:number_of_teachers, 0)
    assign(:school, school)
    render
  end

  it 'shows the Register an ECT starting at your school button' do
    expect(rendered).to have_css('a.govuk-button', text: 'Register an ECT starting at your school')
  end

  context 'when there are no teachers' do
    it 'shows a message that there are no registered ECTs' do
      expect(rendered).to have_css('div.govuk-grid-column-two-thirds p.govuk-body', text: 'Your school currently has no registered early career teachers.')
    end

    it 'shows the Register an ECT starting at your school button' do
      expect(rendered).to have_css('a.govuk-button', text: 'Register an ECT starting at your school')
    end

    it 'does not render the summary component' do
      expect(rendered).not_to have_css('.govuk-summary-card')
    end

    it 'does not render the search box' do
      expect(rendered).not_to have_css('.govuk-form-group label', text: 'Search by name or teacher reference number (TRN)')
    end
  end

  context 'when there are teachers' do
    let(:teacher) { FactoryBot.create(:teacher, trs_first_name: 'Johnnie', trs_last_name: 'Walker') }
    let(:ect_period) { FactoryBot.create(:ect_at_school_period, teacher:, school:) }

    before do
      assign(:filtered_teachers, [teacher])
      assign(:ects, [ect_period])
      assign(:number_of_teachers, 1)
      assign(:school, school)
      render
    end

    it 'renders the summary component' do
      expect(rendered).to have_css('.govuk-summary-card__title', text: 'Johnnie Walker')
    end

    it 'renders the search box' do
      expect(rendered).to have_css('.govuk-form-group label', text: 'Search by name or teacher reference number (TRN)')
    end

    context 'when the filtered teachers is empty' do
      before do
        assign(:filtered_teachers, [])
        assign(:ects, [ect_period])
        assign(:number_of_teachers, 1)
        assign(:school, school)
        render
      end

      it 'renders the no ects text' do
        expect(rendered).to have_css('.govuk-body', text: 'There are no ECTs that match your search.')
      end

      it 'renders the search box' do
        expect(rendered).to have_css('.govuk-form-group label', text: 'Search by name or teacher reference number (TRN)')
      end
    end
  end
end
