require "rails_helper"

RSpec.describe Navigation::PrimaryNavigationComponent, type: :component do
  let(:current_path) { "/" }
  let(:current_user) { FactoryBot.build(:user) }

  subject { described_class.new(current_path:, current_user:) }

  def validate_navigation_items(expected_items)
    expected_items.each do |item|
      expect(rendered_content).to have_link(item[:text], href: item[:href])
    end
  end

  describe "#call" do
    it "renders the service name" do
      render_inline(subject)
      expect(rendered_content).to have_link("Register early career teachers")
    end

    context "when in admin section with admin access" do
      let(:current_path) { "/admin" }
      let(:current_user) { FactoryBot.create(:user) }

      before do
        allow(Admin::Access).to receive(:new).with(current_user).and_return(double(can_access?: true))
      end

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

    context "when in admin section without admin access" do
      let(:current_path) { "/admin" }

      before do
        allow(Admin::Access).to receive(:new).with(current_user).and_return(double(can_access?: false))
      end

      it "renders school navigation items" do
        render_inline(subject)

        expected_items = [
          { text: "Your ECTs", href: "/schools/home/ects" },
          { text: "Your mentors", href: "#" }
        ]

        validate_navigation_items(expected_items)
      end
    end

    context "when in school section" do
      let(:current_path) { "/school" }

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
        expect(rendered_content).to have_link("Register early career teachers", href: "/")
      end
    end

    context "when current page matches a navigation item" do
      let(:current_path) { "/admin/teachers" }
      let(:current_user) { FactoryBot.create(:user) }

      before do
        allow(Admin::Access).to receive(:new).with(current_user).and_return(double(can_access?: true))
      end

      it "marks the current item as active" do
        render_inline(subject)
        expect(rendered_content).to have_css("a[aria-current='page']", text: "Teachers")
      end
    end
  end
end
