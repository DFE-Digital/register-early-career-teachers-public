require "rails_helper"

RSpec.describe Navigation::PrimaryNavigationComponent, type: :component do
  let(:current_path) { "/" }
  let(:nav_selector) { 'nav.govuk-service-navigation__wrapper' }

  subject { described_class.new(current_path:) }

  def validate_navigation_items(expected_items)
    expect(rendered_content).to have_css(nav_selector)

    expected_items.each do |item|
      expect(rendered_content).to have_link(item[:text], href: item[:href])
    end
  end

  describe "#call" do
    it "renders the service name" do
      render_inline(subject)
      expect(rendered_content).to have_link("Register early career teachers")
    end

    context "when in admin section" do
      let(:current_path) { "/admin" }

      it "renders admin navigation items" do
        render_inline(subject)

        expected_items = [
          { text: "Teachers", href: "/admin/teachers" },
          { text: "Organisations", href: "/admin/organisations" },
          { text: "Admin users", href: "#" },
        ]

        validate_navigation_items(expected_items)
      end

      it "sets the correct service URL" do
        render_inline(subject)
        expect(rendered_content).to have_link("Register early career teachers", href: "/admin")
      end
    end

    context "when in school section" do
      let(:current_path) { "/schools" }

      it "renders school navigation items" do
        render_inline(subject)

        expected_items = [
          { text: "Your ECTs", href: "/schools/home/ects" },
          { text: "Your mentors", href: "#" }
        ]

        validate_navigation_items(expected_items)
      end

      it "sets the correct service URL" do
        render_inline(subject)
        expect(rendered_content).to have_link("Register early career teachers", href: "/schools/home/ects")
      end
    end

    context "when in the appropriate body section" do
      let(:current_path) { "/appropriate-body" }

      it "has no navigation items" do
        render_inline(subject)

        expect(rendered_content).not_to have_css(nav_selector)
      end

      it "sets the correct service URL" do
        render_inline(subject)
        expect(rendered_content).to have_link("Register early career teachers", href: "/appropriate-body")
      end
    end

    context "when in the no section" do
      let(:current_path) { "/" }

      it "has no navigation items" do
        render_inline(subject)

        expect(rendered_content).not_to have_css(nav_selector)
      end

      it "sets the correct service URL" do
        render_inline(subject)
        expect(rendered_content).to have_link("Register early career teachers", href: "/")
      end
    end

    context "when current page matches a navigation item" do
      let(:current_path) { "/admin/teachers" }

      it "marks the current item as active" do
        render_inline(subject)
        expect(rendered_content).to have_css("a[aria-current='page']", text: "Teachers")
      end
    end
  end
end
