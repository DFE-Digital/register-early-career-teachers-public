RSpec.describe 'schools/ects/index.html.erb' do
  let(:school) { FactoryBot.create(:school) }

  before do
    assign(:ects, [])
    assign(:teachers, [])
    assign(:number_of_teachers, 0)
    assign(:school, school)
    render
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

    it 'shows the "Add an ECT" button' do
      expect(rendered).to have_css('a.govuk-button', text: 'Add an ECT')
    end

    it 'renders the summary component' do
      expect(rendered).to have_css('.govuk-summary-card__title', text: 'Johnnie Walker')
    end
  end
end
