RSpec.describe Shared::CountCardComponent, type: :component do
  subject(:component) { described_class.new(count: 42, description: "some description", colour: :red) }

  before { render_inline(component) }

  it "renders the count" do
    expect(page).to have_css("h3.govuk-heading-l", text: 42)
  end

  it "renders the description" do
    expect(page).to have_css("h3.govuk-heading-l span.govuk-caption-l", text: "some description")
  end

  it "renders with the colour class" do
    expect(page).to have_css(".app-card--red")
  end
end
