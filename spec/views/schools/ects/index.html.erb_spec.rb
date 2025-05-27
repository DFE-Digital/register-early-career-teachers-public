RSpec.describe 'schools/ects/index.html.erb' do
  let(:school) { FactoryBot.create(:school) }

  before do
    assign(:ects, [])
    assign(:teachers, [])
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
  end
end
