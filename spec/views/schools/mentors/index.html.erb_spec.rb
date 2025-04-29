RSpec.describe 'schools/mentors/index.html.erb' do
  let(:school) { create(:school) }

  before do
    assign(:school, school)
    assign(:mentors, [])
    render
  end

  context 'when there are no mentors' do
    it 'shows a message that there are no mentors' do
      expect(rendered).to have_css('div.govuk-grid-column-two-thirds p.govuk-body', text: 'Your school currently has no registered mentors.')
    end
  end
end
