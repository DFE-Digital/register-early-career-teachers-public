module Navigation
  class Primary
    include Rails.application.routes.url_helpers

    attr_accessor :current_path, :current_user, :inverse

    def initialize(current_path:, current_user: nil, inverse: false)
      @current_path = current_path
      @current_user = current_user
      @inverse = inverse
    end

    def govuk_header_arguments
      { service_name:, service_url:, current_path:, navigation_id:, navigation_items:, inverse: }
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
      if current_path.start_with?("/api/docs/training")
        :training_api_documentation
      elsif current_path.start_with?("/api/docs")
        :api_documentation
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
          { text: "Users", href: admin_users_path, active_when: "/admin/users", if: :can_manage_users? },
          { text: "Tools", href: admin_tools_path, active_when: "/admin/tools", if: :can_see_tools? }
        ],
        school_user: [
          { text: "ECTs", href: schools_ects_home_path, active_when: schools_ects_path },
          { text: "Mentors", href: schools_mentors_home_path, active_when: schools_mentors_path },
          { text: "Induction tutor", href: schools_induction_tutor_path, active_when: "/school/induction-tutor" }
        ],
        training_api_documentation: [
          { text: "Home", href: "/api/docs/training/guidance" },
          { text: "Swagger API documentation", href: "/api/docs/training/v3", active_when: "/api/docs/training/v3" },
          { text: "Release notes", href: "/api/docs/training/guidance/release-notes", active_when: "/api/docs/training/guidance/release-notes" },
          { text: "Guidance", href: "/api/docs/training/guidance/guidance-for-lead-providers", active_when: "/api/docs/training/guidance/guidance-for-lead-providers" }
        ],
        api_documentation: [
          { text: "Home", href: "/api/docs" },
          { text: "Authentication", href: "#authentication", active_when: "#authentication" },
          { text: "Hello World API", href: "#hello-world", active_when: "#hello-world" },
          { text: "Training API", href: api_docs_training_guidance_path, active_when: api_docs_training_guidance_path },
          { text: "Induction API", href: "#induction", active_when: "#induction" },
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
      return false unless current_user_type == :dfe_staff_user
      return false if current_user&.user_manager?

      current_user&.finance_access?
    end

    def can_manage_users?
      return false unless current_user_type == :dfe_staff_user

      current_user&.can_manage_users?
    end

    def can_see_tools?
      current_user&.product_team?
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
