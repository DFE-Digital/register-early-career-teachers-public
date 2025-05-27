RSpec.describe 'schools/ects/index.html.erb' do
  let(:school) { FactoryBot.create(:school) }

  before do
    assign(:ects, [])
    assign(:teachers, [])
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
  end

  context 'when there are teachers' do
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:ect_period) { FactoryBot.create(:ect_at_school_period, teacher:, school:) }

    before do
      assign(:filtered_teachers, [teacher])
      assign(:ects, [ect_period])
      assign(:teachers, [teacher])
      assign(:school, school)
      render
    end

    it 'shows the "Add an ECT" button' do
      expect(rendered).to have_css('a.govuk-button', text: 'Add an ECT')
    end
  end
end
