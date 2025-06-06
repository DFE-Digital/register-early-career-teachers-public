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

    def navigation_area
      if current_path.start_with?('/api/guidance')
        :api_guidance
      else
        current_user_type
      end
    end

    def navigation_items
      {
        appropriate_body_user: [],
        dfe_staff_user: [
          { text: "Teachers", href: admin_teachers_path, active_when: '/admin/teachers' },
          { text: "Organisations", href: admin_organisations_path, active_when: '/admin/organisations' },
          { text: "Finance", href: admin_finance_path, active_when: '/admin/finance' },
        ],
        school_user: [
          { text: "ECTs", href: schools_ects_home_path },
          { text: "Mentors", href: schools_mentors_home_path },
        ],
        api_guidance: [
          { text: "Home", href: '/api/guidance' },
          { text: "Release notes", href: '/api/guidance/release-notes' },
          { text: "Page 1", href: '/api/guidance/page-1' },
          { text: "Page 2", href: '/api/guidance/page-2' },
          { text: "Page 3", href: '/api/guidance/page-3' },
        ]
      }.fetch(navigation_area, [])
    end
  end
end
