module AdminHelper
  def admin_sub_navigation_structure
    @admin_sub_navigation_structure ||= Navigation::Structures::AdminSubNavigation.new.get
  end

  def admin_teacher_name_link(teacher)
    govuk_link_to(teacher_full_name(teacher), admin_teacher_induction_path(teacher))
  end

  def admin_teachers_list_links(teachers)
    govuk_list(teachers.map { |teacher| admin_teacher_name_link(teacher) })
  end

  def admin_latest_induction_complete_with_outcome?(teacher)
    last_induction_period = teacher.last_induction_period
    last_induction_period&.complete? && last_induction_period.outcome?
  end

  def admin_school_navigation_items(school_urn, current_path)
    [
      {
        text: "Overview",
        href: admin_school_overview_path(school_urn),
        current: current_path == admin_school_overview_path(school_urn)
      },
      {
        text: "Teachers",
        href: admin_school_teachers_path(school_urn),
        current: current_path == admin_school_teachers_path(school_urn)
      },
      {
        text: "Partnerships",
        href: admin_school_partnerships_path(school_urn),
        current: current_path == admin_school_partnerships_path(school_urn)
      }
    ]
  end

  def role_name(role)
    User::ROLES.fetch(role.to_sym)
  end

  def role_options
    role_option = Data.define(:identifier, :name)

    User::ROLES.map { |k, v| role_option.new(identifier: k, name: v) }
  end
end
