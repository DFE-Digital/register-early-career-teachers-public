RSpec.describe Navigation::PrimaryNavigationComponent, type: :component do
  let(:current_path) { "/" }
  let(:current_user_type) { nil }
  let(:nav_selector) { 'nav.govuk-service-navigation__wrapper' }
  let(:nav_list_selector) { "#{nav_selector} ul#register-early-career-teachers-service-navigation-list" }

  subject { described_class.new(current_path:, current_user_type:) }

  def validate_navigation_items(expected_items)
    expect(rendered_content).to have_css(nav_list_selector)

    expected_items.each do |item|
      expect(rendered_content).to have_link(item[:text], href: item[:href])
    end
  end

  describe "#call" do
    it "sets service URL to the root path" do
      render_inline(subject)
      expect(rendered_content).to have_link("Register early career teachers", href: "/")
    end

    it "renders the service name" do
      render_inline(subject)
      expect(rendered_content).to have_link("Register early career teachers")
    end

    context "when in admin section" do
      let(:current_path) { "/admin" }
      let(:current_user_type) { :dfe_staff_user }

      it "renders admin navigation items" do
        render_inline(subject)

        expected_items = [
          { text: "Teachers", href: "/admin/teachers" },
          { text: "Organisations", href: "/admin/organisations" },
        ]

        validate_navigation_items(expected_items)
      end
    end

    context "when in school section" do
      let(:current_path) { "/schools" }
      let(:current_user_type) { :school_user }

      it "renders school navigation items" do
        render_inline(subject)

        expected_items = [
          { text: "Your ECTs", href: "/schools/home/ects" },
        ]

        validate_navigation_items(expected_items)
      end
    end

    context "when in the appropriate body section" do
      let(:current_path) { "/appropriate-body" }

      it "has no navigation items" do
        render_inline(subject)

        expect(rendered_content).not_to have_css(nav_selector)
      end
    end

    context "when in no section" do
      let(:current_path) { "/" }
      let(:current_user_type) { nil }

      it "has no navigation items" do
        render_inline(subject)

        expect(rendered_content).not_to have_css(nav_selector)
      end
    end

    context "when current page matches a navigation item" do
      let(:current_path) { "/admin/teachers" }
      let(:current_user_type) { :dfe_staff_user }

      it "marks the current item as active" do
        render_inline(subject)
        expect(rendered_content).to have_css("a[aria-current='page']", text: "Teachers")
      end
    end
  end
end
