RSpec.describe Navigation::PrimaryNavigationComponent, type: :component do
  subject { described_class.new(current_path:, current_user:) }

  let(:current_path) { "/" }
  let(:current_user_type) { nil }
  let(:nav_selector) { "nav.govuk-service-navigation__wrapper" }
  let(:nav_list_selector) { "#{nav_selector} ul#register-early-career-teachers-service-navigation-list" }
  let(:current_user) { double(school_user?: false, user_type: current_user_type, finance_access?: true) }

  def validate_navigation_items(expected_items)
    expect(rendered_content).to have_css(nav_list_selector)

    expect(page).to have_css('nav[aria-label="Menu"] a.govuk-service-navigation__link', count: expected_items.count)

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
          { text: "Schools", href: "/admin/schools" },
          { text: "Organisations", href: "/admin/organisations" },
          { text: "Finance", href: "/admin/finance" },
          { text: "Users", href: "/admin/users" }
        ]

        validate_navigation_items(expected_items)
      end
    end

    context "when in admin section and user does not have finance access" do
      let(:current_path) { "/admin" }
      let(:current_user_type) { :dfe_staff_user }
      let(:current_user) { double(school_user?: false, user_type: current_user_type, finance_access?: false) }

      it "does not render the Finance item" do
        render_inline(subject)

        expect(rendered_content).to have_link("Teachers", href: "/admin/teachers")
        expect(rendered_content).to have_link("Schools", href: "/admin/schools")
        expect(rendered_content).to have_link("Organisations", href: "/admin/organisations")
        expect(rendered_content).to have_link("Users", href: "/admin/users")
        expect(rendered_content).not_to have_link("Finance", href: "/admin/finance")
      end
    end

    context "when inverse: true" do
      subject { described_class.new(current_path:, current_user:, inverse: true) }

      before { render_inline(subject) }

      it "adds the inverse class to the nav" do
        expect(rendered_content).to have_css("section.govuk-service-navigation.govuk-service-navigation--inverse")
      end
    end

    context "when in school section" do
      let(:current_path) { "/schools" }
      let(:current_user_type) { :school_user }

      it "renders school navigation items" do
        render_inline(subject)

        expected_items = [
          { text: "ECTs", href: "/school/home/ects" },
          { text: "Mentors", href: "/school/home/mentors" },
          { text: "Induction tutor", href: "/school/home/induction-tutor" }
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

        ["Swagger API documentation", "Release notes", "Sandbox", "Guidance"].each do |other_page|
          expect(rendered_content).to have_css(".govuk-service-navigation__link", text: other_page)
        end
      end
    end

    context "when dfe user is impersonating a school user" do
      let(:current_user_type) { :dfe_user_impersonating_school_user }
      let(:current_path) { "/schools" }

      it "renders the same items a school user would see" do
        render_inline(subject)

        expected_items = [
          { text: "ECTs", href: "/school/home/ects" },
          { text: "Mentors", href: "/school/home/mentors" },
          { text: "Induction tutor", href: "/school/home/induction-tutor" }
        ]

        validate_navigation_items(expected_items)
      end
    end

    context "when induction information needs updating" do
      before do
        mock_service = instance_double(Schools::InductionTutorDetails, update_required?: true)
        allow(Schools::InductionTutorDetails).to receive(:new)
          .with(current_user)
          .and_return(mock_service)
      end

      it "renders no navigation items" do
        render_inline(subject)

        expect(rendered_content).not_to have_css(nav_selector)
      end
    end
  end
end
