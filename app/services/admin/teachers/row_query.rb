module Admin
  module Teachers
    # Builds the admin teacher table rows. This uses SQL because the
    # index paginates rendered rows rather than teachers, one teacher can
    # appear multiple times, and the default unfiltered view needs to scale
    # to the full teacher dataset.

    class RowQuery
      CONTRACT_PERIOD_NOT_AVAILABLE = "not_available"
      NO_ROLE_ASSIGNED = "no_role_assigned"

      ROLE_NAMES = {
        "ect" => "Early career teacher",
        "mentor" => "Mentor",
      }.freeze

      ROLE_SORT_ORDER = ROLE_NAMES.keys.append(NO_ROLE_ASSIGNED).each_with_index.to_h.freeze

      Row = Data.define(:teacher_id, :name, :trn, :role, :contract_period) do
        def role_name
          return "No role assigned" if role == RowQuery::NO_ROLE_ASSIGNED

          RowQuery::ROLE_NAMES.fetch(role)
        end

        def contract_period_name
          return nil if contract_period.blank?
          return "Not available" if contract_period == RowQuery::CONTRACT_PERIOD_NOT_AVAILABLE

          contract_period
        end
      end

      def initialize(matching_teacher_scope:, role: nil, contract_period: nil)
        @matching_teacher_scope = matching_teacher_scope
        @role = role
        @contract_period = contract_period
      end

      def relation
        filtered_scope.reorder(Arel.sql(order_sql))
      end

      def count
        filtered_scope.except(:order).count(:all)
      end

      def rows(records)
        records.map do |record|
          Row.new(
            teacher_id: record.teacher_id,
            name: record.name,
            trn: record.trn,
            role: record.role,
            contract_period: record.contract_period
          )
        end
      end

    private

      attr_reader :matching_teacher_scope, :role, :contract_period

      def filtered_scope
        scope = row_scope
        scope = scope.where("admin_teacher_rows.role = ?", role) if role.present?
        scope = scope.where("admin_teacher_rows.contract_period = ?", contract_period) if contract_period.present?
        scope
      end

      def row_scope
        Teacher.unscoped
          .from(Arel.sql("(#{row_query_sql}) admin_teacher_rows"))
          .select(
            "admin_teacher_rows.teacher_id",
            "admin_teacher_rows.name",
            "admin_teacher_rows.trn",
            "admin_teacher_rows.role",
            "admin_teacher_rows.contract_period",
            "admin_teacher_rows.name_sort_key",
            "admin_teacher_rows.role_sort_order"
          )
          .readonly(true)
      end

      def row_query_sql
        <<~SQL.squish
          WITH matching_teachers AS (
            #{matching_teachers_sql}
          ),
          teacher_context AS (
            #{teacher_context_sql}
          )
          #{ect_rows_sql}

          UNION ALL

          #{mentor_rows_sql}

          UNION ALL

          #{no_role_rows_sql}
        SQL
      end

      def matching_teachers_sql
        matching_teacher_scope
          .reselect(:id, :trn, :corrected_name, :trs_first_name, :trs_last_name)
          .to_sql
      end

      def teacher_context_sql
        <<~SQL.squish
          SELECT
            matching_teachers.id AS teacher_id,
            matching_teachers.trn,
            #{display_name_sql} AS name,
            LOWER(#{display_name_sql}) AS name_sort_key,
            EXISTS(
              SELECT *
              FROM induction_periods
              WHERE induction_periods.teacher_id = matching_teachers.id
            ) AS has_induction_periods,
            ect_period.id AS ect_period_id,
            ect_training.contract_period AS ect_contract_period,
            mentor_period.id AS mentor_period_id,
            mentor_training.contract_period AS mentor_contract_period
          FROM matching_teachers
          LEFT JOIN LATERAL (
            #{selected_role_period_sql('ect_at_school_periods')}
          ) ect_period ON TRUE
          LEFT JOIN LATERAL (
            #{ect_contract_period_sql}
          ) ect_training ON TRUE
          LEFT JOIN LATERAL (
            #{selected_role_period_sql('mentor_at_school_periods')}
          ) mentor_period ON TRUE
          LEFT JOIN LATERAL (
            #{mentor_contract_period_sql}
          ) mentor_training ON TRUE
        SQL
      end

      def selected_role_period_sql(table_name)
        <<~SQL.squish
          SELECT #{table_name}.id
          FROM #{table_name}
          WHERE #{table_name}.teacher_id = matching_teachers.id
          ORDER BY #{current_or_next_else_latest_order_sql(table_name)}
          LIMIT 1
        SQL
      end

      def ect_contract_period_sql
        <<~SQL.squish
          SELECT
            CASE
              WHEN training_periods.training_programme = 'school_led'
                THEN #{quoted_contract_period_not_available}
              ELSE schedules.contract_period_year::text
            END AS contract_period
          FROM training_periods
          LEFT JOIN schedules ON schedules.id = training_periods.schedule_id
          WHERE training_periods.ect_at_school_period_id = ect_period.id
          ORDER BY #{current_or_next_else_latest_order_sql('training_periods')}
          LIMIT 1
        SQL
      end

      def mentor_contract_period_sql
        <<~SQL.squish
          SELECT schedules.contract_period_year::text AS contract_period
          FROM training_periods
          LEFT JOIN schedules ON schedules.id = training_periods.schedule_id
          WHERE training_periods.mentor_at_school_period_id = mentor_period.id
          ORDER BY #{current_or_next_else_latest_order_sql('training_periods')}
          LIMIT 1
        SQL
      end

      def ect_rows_sql
        role_rows_sql(
          role: "ect",
          contract_period_sql: "teacher_context.ect_contract_period",
          where_sql: "teacher_context.ect_period_id IS NOT NULL OR teacher_context.has_induction_periods"
        )
      end

      def mentor_rows_sql
        role_rows_sql(
          role: "mentor",
          contract_period_sql: "teacher_context.mentor_contract_period",
          where_sql: "teacher_context.mentor_period_id IS NOT NULL"
        )
      end

      def no_role_rows_sql
        role_rows_sql(
          role: NO_ROLE_ASSIGNED,
          contract_period_sql: "NULL",
          where_sql: <<~SQL.squish
            teacher_context.ect_period_id IS NULL
              AND teacher_context.mentor_period_id IS NULL
              AND NOT teacher_context.has_induction_periods
          SQL
        )
      end

      def role_rows_sql(role:, contract_period_sql:, where_sql:)
        <<~SQL.squish
          SELECT
            teacher_context.teacher_id,
            teacher_context.name,
            teacher_context.trn,
            #{connection.quote(role)} AS role,
            #{contract_period_sql} AS contract_period,
            teacher_context.name_sort_key,
            #{ROLE_SORT_ORDER.fetch(role)} AS role_sort_order
          FROM teacher_context
          WHERE #{where_sql}
        SQL
      end

      def order_sql
        "admin_teacher_rows.name_sort_key ASC, admin_teacher_rows.role_sort_order ASC, admin_teacher_rows.teacher_id ASC"
      end

      def display_name_sql
        <<~SQL.squish
          COALESCE(
            NULLIF(matching_teachers.corrected_name, ''),
            NULLIF(
              CONCAT_WS(
                ' ',
                NULLIF(NULLIF(matching_teachers.trs_first_name, ''), '.'),
                NULLIF(NULLIF(matching_teachers.trs_last_name, ''), '.')
              ),
              ''
            ),
            'Unknown'
          )
        SQL
      end

      def current_or_next_else_latest_order_sql(table_name)
        # Prefer current/future records, otherwise fall back to the most recent past record.
        active_or_future_sql = "#{table_name}.finished_on IS NULL OR #{table_name}.finished_on > CURRENT_DATE"

        <<~SQL.squish
          CASE
            WHEN #{active_or_future_sql} THEN 0
            ELSE 1
          END ASC,
          CASE
            WHEN #{active_or_future_sql} THEN #{table_name}.started_on
          END ASC NULLS LAST,
          CASE
            WHEN #{active_or_future_sql} THEN NULL
            ELSE #{table_name}.started_on
          END DESC NULLS LAST
        SQL
      end

      def quoted_contract_period_not_available
        connection.quote(CONTRACT_PERIOD_NOT_AVAILABLE)
      end

      def connection
        Teacher.connection
      end
    end
  end
end
