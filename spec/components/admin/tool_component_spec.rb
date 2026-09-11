describe Admin::ToolComponent, type: :component do
  let(:component) { described_class.new(name: "Blazer", href: "/admin/blazer") }

  before do
    render_inline(component) { "Run SQL queries against the database." }
  end

  it "renders the tool name as a heading linking to the tool" do
    expect(rendered_content).to have_css("h2 a[href='/admin/blazer']", text: "Blazer")
  end

  it "renders the description" do
    expect(rendered_content).to have_css("p", text: "Run SQL queries against the database.")
  end
end
