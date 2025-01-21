module Navigation
  class PrimaryNavigationComponent < ViewComponent::Base
    attr_accessor :current_path, :current_user_type

    def initialize(current_path:, current_user_type:)
      super

      @current_path = current_path
      @current_user_type = current_user_type
    end

    def call
      govuk_service_navigation(service_name:, service_url:, current_path:, navigation_id:, navigation_items:)
    end

  private

    def service_name
      "Register early career teachers"
    end

    def service_url
      '/'
    end

    def navigation_id
      'register-early-career-teachers-service-navigation-list'
    end

    def navigation_items
      return [] unless current_user_type

      {
        appropriate_body_user: [],
        dfe_staff_user: [
          { text: "Teachers", href: admin_teachers_path },
          { text: "Organisations", href: admin_organisations_path },
        ],
        school_user: [
          { text: "Your ECTs", href: schools_ects_home_path },
        ]
      }.fetch(current_user_type)
    end
  end
end
