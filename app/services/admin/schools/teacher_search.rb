module Admin
  module Schools
    class TeacherSearch
      ROLE_PERIODS = {
        "ect" => :ect_at_school_periods,
        "mentor" => :mentor_at_school_periods
      }.freeze

      def initialize(school:, query_string: nil, role: nil, contract_period: nil)
        @school = school
        @query_string = query_string.to_s.strip
        @role = role.to_s.presence
        @contract_period = contract_period.to_s.presence
      end

      def rows
        role_periods
          .select { |_current_role, period| contract_period_matches?(period:) }
          .map { |current_role, period| row_for(role: current_role, period:) }
          .sort_by { |row| [-row.teacher.created_at.to_f, row.role] }
      end

      def has_current_teachers?
        ROLE_PERIODS.values.any? do |association|
          school.public_send(association).contains_today.exists?
        end
      end

    private

      attr_reader :school, :query_string, :role, :contract_period

      def role_periods
        roles.flat_map do |current_role|
          current_role_periods(current_role).map { |period| [current_role, period] }
        end
      end

      def roles
        return ROLE_PERIODS.keys if role.blank?
        return [role] if ROLE_PERIODS.key?(role)

        []
      end

      def current_role_periods(current_role)
        scope = school
          .public_send(ROLE_PERIODS.fetch(current_role))
          .contains_today
          .preload(:teacher, latest_training_period: :schedule)

        return scope if query_string.blank?

        scope.where(teacher_id: matching_teachers.select(:id))
      end

      def matching_teachers
        @matching_teachers ||= ::Admin::Teachers::NameOrIdentifierSearch.new(
          query_string:
        ).matching_teacher_scope
      end

      def row_for(role:, period:)
        ::Admin::Teachers::Rows::Row.new(
          teacher: period.teacher,
          role:,
          contract_period: contract_period_for(period)
        )
      end

      def contract_period_matches?(period:)
        return true if contract_period.blank?

        contract_period_for(period) == contract_period
      end

      def contract_period_for(period)
        training_period = period.latest_training_period
        return ::Admin::Teachers::Rows::CONTRACT_PERIOD_NOT_AVAILABLE if training_period.blank? || training_period.school_led_training_programme?

        training_period.schedule&.contract_period_year&.to_s ||
          ::Admin::Teachers::Rows::CONTRACT_PERIOD_NOT_AVAILABLE
      end
    end
  end
end
