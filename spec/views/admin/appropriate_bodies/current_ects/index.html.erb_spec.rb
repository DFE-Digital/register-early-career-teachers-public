RSpec.describe 'admin/appropriate_bodies/current_ects/index.html.erb' do
  include Pagy::Backend

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:number_of_teachers) { 2 }
  let!(:teachers) { FactoryBot.create_list(:teacher, number_of_teachers) }

  before do
    pagy, teachers = pagy(Teacher.all)

    assign(:appropriate_body, appropriate_body)
    assign(:teachers, teachers)
    assign(:pagy, pagy)

    controller.request.path_parameters[:appropriate_body_id] = appropriate_body.id
  end

  it 'contains a list of teachers' do
    render

    expect(view.content_for(:page_title)).to start_with('Current ECTs')
    expect(rendered).to have_css('.govuk-summary-card', count: number_of_teachers)
  end

  it 'shows each teacher name and a show link to their profile page' do
    render

    teachers.each do |teacher|
      expect(rendered).to have_css('.govuk-summary-card__title', text: Teachers::Name.new(teacher).full_name)
      expect(rendered).to have_link('Show', href: admin_teacher_path(teacher))
    end
  end

  it 'shows a search form' do
    render

    expect(rendered).to have_css('form')
    expect(rendered).to have_css('label', text: 'Search ECTs')
  end
end
