RSpec.describe Navigation::SecondaryNavigationComponent, type: :component do
  subject { described_class.new(items:) }

  let(:items) do
    [
      { text: "Overview", href: "/overview", current: true },
      { text: "Teachers", href: "/teachers", current: false },
      { text: "Settings", href: "/settings", current: false, classes: "custom-class" }
    ]
  end

  describe "#render?" do
    context "when items are present" do
      it "returns true" do
        expect(subject.render?).to be true
      end
    end

    context "when items are empty" do
      subject { described_class.new(items: []) }

      it "returns false" do
        expect(subject.render?).to be false
      end
    end

    context "when items are nil" do
      subject { described_class.new(items: nil) }

      it "returns false" do
        expect(subject.render?).to be false
      end
    end
  end

  describe "rendering" do
    before { render_inline(subject) }

    it "renders the navigation element with correct classes" do
      expect(rendered_content).to have_css("nav.x-govuk-secondary-navigation")
    end

    it "renders the navigation list" do
      expect(rendered_content).to have_css("ul.x-govuk-secondary-navigation__list")
    end

    it "renders all navigation items" do
      items.each do |item|
        expect(rendered_content).to have_css("li.x-govuk-secondary-navigation__list-item")
        expect(rendered_content).to have_link(item[:text], href: item[:href])
      end
    end

    it "marks the current item correctly" do
      expect(rendered_content).to have_css(".x-govuk-secondary-navigation__list-item--current a", text: "Overview")
      expect(rendered_content).to have_css('a[aria-current="page"]', text: "Overview")
    end

    it "does not mark non-current items as current" do
      expect(rendered_content).not_to have_css(".x-govuk-secondary-navigation__list-item--current a", text: "Teachers")
      expect(rendered_content).not_to have_css('a[aria-current="page"]', text: "Teachers")
    end

    it "includes custom classes when provided" do
      expect(rendered_content).to have_css("li.custom-class", text: "Settings")
    end

    it "sets default aria-label" do
      expect(rendered_content).to have_css('nav[aria-label="Secondary Menu"]')
    end
  end

  describe "with custom attributes" do
    subject do
      described_class.new(
        items:,
        labelled_by: "page-title",
        visually_hidden_title: "Custom Menu",
        classes: "custom-nav-class",
        attributes: { "data-module" => "custom-module" }
      )
    end

    before { render_inline(subject) }

    it "uses labelled_by instead of aria-label" do
      expect(rendered_content).to have_css('nav[aria-labelledby="page-title"]')
      expect(rendered_content).not_to have_css("nav[aria-label]")
    end

    it "applies custom classes" do
      expect(rendered_content).to have_css("nav.x-govuk-secondary-navigation.custom-nav-class")
    end

    it "applies custom attributes" do
      expect(rendered_content).to have_css('nav[data-module="custom-module"]')
    end
  end

  describe "with visually hidden title" do
    subject do
      described_class.new(
        items:,
        visually_hidden_title: "Page Navigation"
      )
    end

    before { render_inline(subject) }

    it "uses the custom visually hidden title as aria-label" do
      expect(rendered_content).to have_css('nav[aria-label="Page Navigation"]')
    end
  end
end
