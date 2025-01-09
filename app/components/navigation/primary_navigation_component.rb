module Navigation
  class PrimaryNavigationComponent < ViewComponent::Base
    attr_accessor :current_path, :area

    def initialize(current_path:)
      super

      @current_path = current_path
      @area = case current_path
              when %r{\A/admin}            then :admin
              when %r{\A/appropriate-body} then :appropriate_body
              when %r{\A/schools}          then :school
              else :none
              end
    end

    def call
      govuk_service_navigation(service_name:, service_url:, current_path:, navigation_items:)
    end

  private

    def service_name
      "Register early career teachers"
    end

    def service_url
      {
        admin: '/admin',
        appropriate_body: '/appropriate-body',
        school: '/schools/home/ects',
        none: '/'
      }.fetch(area)
    end

    def navigation_items
      {
        admin: [
          { text: "Teachers", href: admin_teachers_path },
          { text: "Organisations", href: admin_organisations_path },
          { text: "Admin users", href: "#" },
        ],
        school: [
          { text: "Your ECTs", href: schools_ects_home_path },
          { text: "Your mentors", href: "#" }
        ],
        appropriate_body: [],
        none: []
      }.fetch(area)
    end
  end
end
