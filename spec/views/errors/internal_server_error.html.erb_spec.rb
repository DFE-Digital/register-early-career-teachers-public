RSpec.describe "errors/internal_server_error.html.erb" do
  before { render }

  it "display support email" do
    expect(rendered).to have_link('teacher.induction@education.gov.uk', href: 'mailto:teacher.induction@education.gov.uk')
  end
end
