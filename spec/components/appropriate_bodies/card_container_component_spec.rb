RSpec.describe AppropriateBodies::CardContainerComponent, type: :component do
  subject(:component) { described_class.new }

  before do
    render_inline(component) do
      "Card content goes here"
    end
  end

  it "renders the container with correct classes" do
    expect(page).to have_css(".dfe-grid-container.govuk-grid-row.govuk-\\!-margin-bottom-7")
  end

  it "yields the content" do
    expect(page).to have_text("Card content goes here")
  end
end
