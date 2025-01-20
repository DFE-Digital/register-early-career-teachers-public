RSpec.describe "appropriate_bodies/teachers/index.html.erb" do
  let(:appropriate_body) { FactoryBot.build(:appropriate_body) }
  let(:teachers) { Teacher.all }

  before do
    assign(:appropriate_body, appropriate_body)
    assign(:teachers, Teacher.all)

    render
  end

  describe 'heading and title' do
    it 'sets the page title and heading to the appropriate body name' do
      expect(view.content_for(:page_header)).to have_css('h1', text: appropriate_body.name)
    end

    it 'sets the page title and heading to the appropriate body name' do
      expect(view.content_for(:page_title)).to start_with(appropriate_body.name)
    end
  end

  describe 'form' do
    it "includes a form with a 'Search' submission button" do
      expect(rendered).to have_css('form button', text: 'Search')
    end

    it "includes a form with a 'Reset' link" do
      expect(rendered).to have_css("form a", text: 'Reset')
      expect(rendered).to have_link('Reset', href: ab_teachers_path)
    end
  end
end
