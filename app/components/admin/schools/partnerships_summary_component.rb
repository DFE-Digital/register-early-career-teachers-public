module Admin
  module Schools
    class PartnershipsSummaryComponent < ApplicationComponent
      include TeacherHelper

      attr_reader :school

      def initialize(school:)
        @school = school
      end

      def school_partnerships
        @school_partnerships ||= school.school_partnerships
          .includes(
            :contract_period,
            :lead_provider,
            :delivery_partner,
            training_periods: [
              { ect_at_school_period: :teacher },
              { mentor_at_school_period: :teacher }
            ]
          )
          .latest_by_contract_year
      end

      def school_partnerships_by_year
        @school_partnerships_by_year ||= school_partnerships.group_by { |school_partnership| school_partnership.contract_period.year }
      end

      def contract_years
        @contract_years ||= school_partnerships_by_year.keys.sort.reverse
      end

      def school_partnership_title(school_partnership)
        "#{school_partnership.lead_provider.name} and #{school_partnership.delivery_partner.name}"
      end

      def teacher_links(school_partnership, role:)
        period_type = role == :ect ? :ect_at_school_period : :mentor_at_school_period

        teachers_for(school_partnership.training_periods, period_type)
          .map { |teacher| govuk_link_to(teacher_full_name(teacher), admin_teacher_induction_path(teacher)) }
      end

      def teachers_for(training_periods, period_type)
        training_periods
          .select { |period| period.started_on <= Time.zone.today && period.ongoing_today? }
          .filter_map { |period| period.public_send(period_type)&.teacher }
          .uniq
          .sort_by { |teacher| teacher_full_name(teacher) }
      end

      def teacher_values(links)
        links.any? ? safe_join(links, tag.br) : "None assigned"
      end
    end
  end
end
