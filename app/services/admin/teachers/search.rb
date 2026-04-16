module Admin
  module Teachers
    class Search
      CONTRACT_PERIOD_NOT_AVAILABLE = "not_available"
      NO_ROLE_ASSIGNED = "no_role_assigned"

      ROLE_NAMES = {
        "ect" => "Early career teacher",
        "mentor" => "Mentor",
      }.freeze

      ROLE_SORT_ORDER = ROLE_NAMES.keys.append(NO_ROLE_ASSIGNED).each_with_index.to_h.freeze

      Row = Data.define(:teacher, :role, :contract_period) do
        def name
          ::Teachers::Name.new(teacher).full_name
        end

        def role_name
          return "No role assigned" if role == Search::NO_ROLE_ASSIGNED

          Search::ROLE_NAMES.fetch(role)
        end

        def contract_period_name
          return nil if contract_period.blank?
          return "Not available" if contract_period == Search::CONTRACT_PERIOD_NOT_AVAILABLE

          contract_period
        end

        delegate :trn, to: :teacher
      end

      def initialize(query_string: nil, role: nil, contract_period: nil)
        @query_string = query_string.to_s.strip
        @role = role.to_s.presence
        @contract_period = contract_period.to_s.presence
      end

      def search
        rows = teacher_rows
        rows = filter_by_role(rows)
        rows = filter_by_contract_period(rows)

        sort_rows(rows)
      end

    private

      attr_reader :query_string, :role, :contract_period

      def teacher_scope
        matching(Teacher.all).preload(
          :induction_periods,
          { current_or_next_ect_at_school_period: training_period_preload },
          { latest_ect_at_school_period: training_period_preload },
          { current_or_next_mentor_at_school_period: training_period_preload },
          { latest_mentor_at_school_period: training_period_preload }
        )
      end

      def matching(scope)
        return scope if query_string.blank?

        return scope.where(trn: query_string) if query_string.match?(/\A\d{7}\z/)

        scope.search(query_string).or(api_participant_id_matches(scope))
      end

      def api_participant_id_matches(scope)
        escaped_query = ActiveRecord::Base.sanitize_sql_like(query_string)

        scope.where("CAST(teachers.api_id AS text) ILIKE ?", "%#{escaped_query}%")
      end

      def invalid_tsquery?(error)
        error.cause.is_a?(PG::SyntaxError) &&
          error.cause.message.include?("tsquery")
      end

      def rows_for_teacher(teacher)
        # This is role based, so one teacher can produce multiple rows.
        rows = []
        rows << build_row(teacher:, role: "ect", role_period: role_period_for(teacher, "ect")) if ect?(teacher)
        rows << build_row(teacher:, role: "mentor", role_period: role_period_for(teacher, "mentor")) if mentor?(teacher)

        return rows if rows.any?

        [build_row(teacher:, role: NO_ROLE_ASSIGNED)]
      end

      def teacher_rows
        teacher_scope.flat_map { |teacher| rows_for_teacher(teacher) }
      rescue ActiveRecord::StatementInvalid => e
        raise unless invalid_tsquery?(e)

        []
      end

      def ect?(teacher)
        teacher.current_or_next_ect_at_school_period.present? ||
          teacher.latest_ect_at_school_period.present? ||
          teacher.induction_periods.any?
      end

      def mentor?(teacher)
        teacher.current_or_next_mentor_at_school_period.present? ||
          teacher.latest_mentor_at_school_period.present?
      end

      def role_period_for(teacher, role)
        teacher.public_send("current_or_next_#{role}_at_school_period") ||
          teacher.public_send("latest_#{role}_at_school_period")
      end

      def build_row(teacher:, role:, role_period: nil)
        Row.new(
          teacher:,
          role:,
          contract_period: contract_period_for(role_period)
        )
      end

      def contract_period_for(role_period)
        training_period = training_period_for(role_period)
        return if training_period.blank?
        return CONTRACT_PERIOD_NOT_AVAILABLE if training_period.for_ect? && training_period.school_led_training_programme?

        training_period.schedule&.contract_period_year&.to_s
      end

      def training_period_for(role_period)
        role_period&.current_or_next_training_period || role_period&.latest_training_period
      end

      def training_period_preload
        {
          current_or_next_training_period: :schedule,
          latest_training_period: :schedule
        }
      end

      def filter_by_role(rows)
        return rows if role.blank?

        rows.select { |row| row.role == role }
      end

      def filter_by_contract_period(rows)
        return rows if contract_period.blank?

        rows.select { |row| row.contract_period == contract_period }
      end

      def sort_rows(rows)
        rows.sort_by { |row| row_sort_key(row) }
      end

      def row_sort_key(row)
        [
          row.name.to_s.downcase,
          ROLE_SORT_ORDER.fetch(row.role),
          row.teacher.id
        ]
      end
    end
  end
end
