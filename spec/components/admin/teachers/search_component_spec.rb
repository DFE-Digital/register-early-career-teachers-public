RSpec.describe Admin::Teachers::SearchComponent, type: :component do
  subject(:rendered) { render_inline(described_class.new(form_url:, filter_params:)) }

  let!(:contract_period) { FactoryBot.create(:contract_period, year: 2024) }
  let(:form_url) { "/anything" }
  let(:filter_params) { { q: "Goku", role: "mentor", contract_period: "2024" } }

  it "renders the search field" do
    expect(rendered).to have_field("Search for teacher", with: "Goku")
  end

  it "renders the role filter" do
    expect(rendered).to have_select(
      "Role",
      selected: "Mentor",
      options: ["All", "Early career teacher", "Mentor"]
    )
  end

  it "renders the contract period filter" do
    expect(rendered).to have_select(
      "Contract period",
      selected: "2024",
      options: ["All", "2024", "Not available"]
    )
  end

  it "submits to the supplied URL" do
    expect(rendered).to have_css("form[action='#{form_url}'][method='get']")
    expect(rendered).to have_button("Search")
  end
end
