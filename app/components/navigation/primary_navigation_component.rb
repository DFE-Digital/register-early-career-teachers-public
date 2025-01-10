module Navigation
  class PrimaryNavigationComponent < ViewComponent::Base
    attr_accessor :current_path, :current_user_type

    def initialize(current_path:, current_user_type:)
      super

      @current_path = current_path
      @current_user_type = current_user_type
    end

    def call
      govuk_service_navigation(service_name:, service_url:, current_path:, navigation_items:)
    end

  private

    def service_name
      "Register early career teachers"
    end

    def service_url
      '/'
    end

    def navigation_items
      return [] if current_user_type.nil?

      {
        dfe_staff_user: [
          { text: "Teachers", href: admin_teachers_path },
          { text: "Organisations", href: admin_organisations_path },
          { text: "Admin users", href: "#" },
        ],
        school_user: [
          { text: "Your ECTs", href: schools_ects_home_path },
          { text: "Your mentors", href: "#" }
        ],
        appropriate_body_user: [],
      }.fetch(current_user_type)
    end
  end
end
