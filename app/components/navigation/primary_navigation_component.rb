module Navigation
  class PrimaryNavigationComponent < ViewComponent::Base
    attr_accessor :current_path, :current_user_type, :inverse

    def initialize(current_path:, current_user_type:, inverse: false)
      super

      @current_path = current_path
      @current_user_type = current_user_type
      @inverse = inverse
    end

    def call
      govuk_service_navigation(service_name:, service_url:, current_path:, navigation_id:, navigation_items:, inverse:)
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
          { text: "Bulk uploads", href: admin_bulk_batches_path, active_when: '/admin/bulk' },
        ],
        school_user: [
          { text: "ECTs", href: schools_ects_home_path },
          { text: "Mentors", href: schools_mentors_home_path },
        ],
        api_guidance: [
          { text: "Home", href: '/api/guidance' },
          { text: "Swagger API documentation", href: '/api/guidance/swagger-api-documentation' },
          { text: "Release notes", href: '/api/guidance/release-notes' },
          { text: "Sandbox", href: '/api/guidance/sandbox' },
          { text: "Guidance", href: '/api/guidance/guidance-for-lead-providers' },
        ]
      }.fetch(navigation_area, [])
    end
  end
end
