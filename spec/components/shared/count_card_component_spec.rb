RSpec.describe Shared::CountCardComponent, type: :component do
  subject(:component) do
    described_class.new(count:, description:, **options)
  end

  let(:count) { "42" }
  let(:description) { "some description" }
  let(:options) { {} }

  before { render_inline(component) }

  it "renders the count" do
    expect(page).to have_css("h3.govuk-heading-l", text: count)
  end

  it "renders the description" do
    expect(page).to have_css("h3.govuk-heading-l span.govuk-caption-l", text: description)
  end

  context "with a colour" do
    let(:options) { { colour: :red } }

    it "renders with the colour class" do
      expect(page).to have_css(".app-card--red")
    end
  end
end
