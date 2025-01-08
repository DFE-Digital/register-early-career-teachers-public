module Navigation
  class PrimaryNavigationComponent < ViewComponent::Base
    attr_accessor :current_path, :current_user

    def initialize(current_path:, current_user:)
      super
      @current_user = current_user
      @current_path = current_path
    end

    def call
      govuk_service_navigation(service_name: "Register early career teachers", service_url: service_url) do |service_navigation|
        navigation_items.each do |item|
          service_navigation.with_navigation_item(
            text: item[:text],
            href: item[:href],
            current: current_page?(item[:href])
          )
        end
      end
    end

  private

    def service_url
      if current_path.start_with?("/admin")
        "/admin"
      else
        "/"
      end
    end

    def navigation_items
      if admin_section? && admin_access?
        admin_navigation_items
      else
        school_navigation_items
      end
    end

    def admin_navigation_items
      [
        { text: "Teachers", href: "/admin/teachers" },
        { text: "Organisations", href: "/admin/organisations" },
        { text: "Admin users", href: "#" },
      ]
    end

    def school_navigation_items
      [
        { text: "Your ECTs", href: schools_ects_home_path },
        { text: "Your mentors", href: "#" }
      ]
    end

    def admin_section?
      current_path.start_with?("/admin")
    end

    def admin_access?
      Admin::Access.new(current_user).can_access?
    end

    def current_page?(path)
      current_path == path
    end
  end
end
