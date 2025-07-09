RSpec.describe "api/guidance/show.html.erb" do
  before { render }

  it 'shows the correct title' do
    title_text = 'API guidance'
    expect(view.content_for(:page_title)).to have_text(title_text)
  end

  it 'shows the correct heading' do
    header_text = 'Lead provider guidance: early career training programme'
    expect(view.content_for(:page_header)).to have_text(header_text)
  end
end
