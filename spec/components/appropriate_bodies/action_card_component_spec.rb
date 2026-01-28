RSpec.describe AppropriateBodies::ActionCardComponent, type: :component do
  subject(:component) do
    described_class.new(url:, heading:, body:)
  end

  let(:url) { "/some/path" }
  let(:heading) { "42" }
  let(:body) { "ECT induction records to review" }

  before { render_inline(component) }

  it "renders a link with the correct url" do
    expect(page).to have_link(href: url)
  end

  it "renders the heading" do
    expect(page).to have_css("h3.govuk-heading-l", text: heading)
  end

  it "renders the body text" do
    expect(page).to have_css("p.govuk-body", text: body)
  end

  it "renders the action card styling" do
    expect(page).to have_css(".action-card.dfe-card")
  end
end
