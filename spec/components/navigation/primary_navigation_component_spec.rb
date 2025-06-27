RSpec.describe Navigation::PrimaryNavigationComponent, type: :component do
  subject { described_class.new(current_path:, current_user_type:) }

  let(:current_path) { "/" }
  let(:current_user_type) { nil }
  let(:nav_selector) { 'nav.govuk-service-navigation__wrapper' }
  let(:nav_list_selector) { "#{nav_selector} ul#register-early-career-teachers-service-navigation-list" }

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

    context 'when inverse: true' do
      subject { described_class.new(current_path:, current_user_type:, inverse: true) }

      before { render_inline(subject) }

      it 'adds the inverse class to the nav' do
        expect(rendered_content).to have_css('section.govuk-service-navigation.govuk-service-navigation--inverse')
      end
    end

    context "when in school section" do
      let(:current_path) { "/schools" }
      let(:current_user_type) { :school_user }

      it "renders school navigation items" do
        render_inline(subject)

        expected_items = [
          { text: "ECTs", href: "/schools/home/ects" },
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

    context "when in api guidance section" do
      let(:current_path) { "/api/guidance" }
      let(:current_user_type) { nil }

      it "marks the home page as active" do
        render_inline(subject)

        expect(rendered_content).to have_css("a[aria-current='page']", text: "Home")
      end

      it "lists the other pages" do
        render_inline(subject)

        ["Technical documentation", "Release notes", "Sandbox (test) environments", "Programme guidance"].each do |other_page|
          expect(rendered_content).to have_css(".govuk-service-navigation__link", text: other_page)
        end
      end
    end
  end
end
