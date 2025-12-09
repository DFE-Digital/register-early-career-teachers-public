module Navigation
  class PrimaryNavigationComponent < ApplicationComponent
    attr_accessor :current_path, :current_user, :inverse

    def initialize(current_path:, current_user: nil, inverse: false)
      @current_path = current_path
      @current_user = current_user
      @inverse = inverse
    end

    def call
      govuk_service_navigation(
        service_name:,
        service_url:,
        current_path:,
        navigation_id:,
        navigation_items:,
        inverse:
      )
    end

  private

    def service_name
      "Register early career teachers"
    end

    def service_url
      "/"
    end

    def navigation_id
      "register-early-career-teachers-service-navigation-list"
    end

    def navigation_area
      if current_path.start_with?("/api/guidance")
        :api_guidance
      elsif current_user_type == :dfe_user_impersonating_school_user
        :school_user
      else
        current_user_type
      end
    end

    def navigation_items
      return {} if induction_information_needs_update?

      items = items_by_area.fetch(navigation_area, [])
      filtered_items(items)
    end

    def items_by_area
      {
        appropriate_body_user: [],
        dfe_staff_user: [
          { text: "Teachers", href: admin_teachers_path, active_when: "/admin/teachers" },
          { text: "Schools", href: admin_schools_path, active_when: "/admin/schools" },
          { text: "Organisations", href: admin_organisations_path, active_when: "/admin/organisations" },
          { text: "Finance", href: admin_finance_path, active_when: "/admin/finance", if: :can_see_finance? },
          { text: "Users", href: admin_users_path, active_when: "/admin/users" }
        ],
        school_user: [
          { text: "ECTs", href: schools_ects_home_path },
          { text: "Mentors", href: schools_mentors_home_path },
          { text: "Induction tutor", href: schools_induction_tutor_path }
        ],
        api_guidance: [
          { text: "Home", href: "/api/guidance" },
          { text: "Swagger API documentation", href: "/api/guidance/swagger-api-documentation" },
          { text: "Release notes", href: "/api/guidance/release-notes", active_when: "/api/guidance/release-notes" },
          { text: "Sandbox", href: "/api/guidance/sandbox" },
          { text: "Guidance", href: "/api/guidance/guidance-for-lead-providers", active_when: "/api/guidance/guidance-for-lead-providers" },
        ]
      }
    end

    def filtered_items(items)
      items
        .select { |item| visible_item?(item) }
        .map { |item| item.slice(:text, :href, :active_when) }
    end

    def visible_item?(item)
      condition = item[:if]
      return true if condition.nil?
      return send(condition) if respond_to?(condition, true)

      true
    end

    def can_see_finance?
      current_user&.finance_access?
    end

    def current_user_type
      current_user&.user_type
    end

    def induction_information_needs_update?
      induction_details_service.update_required?
    end

    def induction_details_service
      @induction_details_service ||= Schools::InductionTutorDetails.new(current_user)
    end
  end
end
