RSpec.describe Shared::ActionCountCardComponent, type: :component do
  subject(:component) do
    described_class.new(url:, count:, description:, colour:)
  end

  let(:url) { "/some/path" }
  let(:count) { "42" }
  let(:description) { "ECT induction records to review" }
  let(:colour) { "grey-and-blue" }

  before { render_inline(component) }

  it "renders a link with the correct url" do
    expect(page).to have_link(href: url)
  end

  it "renders the count" do
    expect(page).to have_css("h3.govuk-heading-l", text: count)
  end

  it "renders the description" do
    expect(page).to have_css("h3.govuk-heading-l span.govuk-caption-l", text: description)
  end

  it "renders the action card styling" do
    expect(page).to have_css(".action-card")
    expect(page).to have_css(".card.app-card--grey-and-blue")
  end
end
