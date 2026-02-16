RSpec.describe UnclaimedIndex::SearchSectionComponent, type: :component do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(query:, form_url:) }
  let(:form_url) { "/appropriate-body/schools-data/claimable" }

  context "with no query" do
    let(:query) { nil }

    it "renders search form with correct label" do
      expect(rendered.css("label").text).to include("Search by name or teacher reference number (TRN)")
    end

    it "renders search input with no value" do
      input_element = rendered.css('input[name="q"]').first
      expect(input_element["value"]).to be_blank
    end

    it "renders reset button linking to form_url" do
      expect(rendered).to have_link("Reset", href: form_url)
    end
  end

  context "with a query" do
    let(:query) { "Alice Smith" }

    it "renders search input with query value" do
      input_element = rendered.css('input[name="q"]').first
      expect(input_element["value"]).to eq("Alice Smith")
    end

    it "renders reset button linking to form_url" do
      expect(rendered).to have_link("Reset", href: form_url)
    end
  end

  describe "form structure" do
    let(:query) { nil }

    it "renders form with GET method and correct action" do
      form = rendered.css("form").first
      expect(form["method"]).to eq("get")
      expect(form["action"]).to eq(form_url)
    end

    it "renders hint text" do
      expect(rendered.css(".govuk-hint").text).to include("Enter a name or TRN")
    end

    it "renders submit button" do
      button = rendered.css('button[type="submit"]').first
      expect(button.text).to eq("Search")
    end

    it "renders reset button with secondary styling" do
      expect(rendered).to have_link("Reset", class: ["govuk-button", "govuk-button--secondary"])
    end
  end
end
