module Admin
  module Teachers
    class Search
      # Builds the teacher relation for the admin teacher index. Pagination stays
      # teacher based and DB backed, but contract_period filtering is applied
      # in SQL so it works across the full dataset before pagination.

      def initialize(query_string: nil, role: nil, contract_period: nil)
        @query_string = query_string.to_s.strip
        @role = role.to_s.presence
        @contract_period = contract_period.to_s.presence
      end

      def teacher_scope
        preload_associations(filtered_teacher_scope)
          .reorder(created_at: :desc)
      end

    private

      attr_reader :query_string, :role, :contract_period

      def filtered_teacher_scope
        scope = matching(Teacher.unscoped)
        scope = filter_teachers_by_role(scope)
        filter_teachers_by_contract_period(scope)
      end

      def preload_associations(scope)
        scope.preload(
          :induction_periods,
          { latest_ect_at_school_period: training_period_preload },
          { latest_mentor_at_school_period: training_period_preload }
        )
      end

      def matching(scope)
        scope.merge(NameOrIdentifierSearch.new(query_string:).matching_teacher_scope)
      end

      def filter_teachers_by_role(scope)
        return scope if role.blank?

        scope.where(id: teacher_ids_for_role(role))
      end

      def filter_teachers_by_contract_period(scope)
        return scope if contract_period.blank?

        clauses = contract_period_filter_clauses
        sql = clauses.map { |clause| "(#{clause})" }.join(" OR ")

        if contract_period_not_available_filter?
          scope.where(sql)
        else
          scope.where(sql, contract_period:)
        end
      end

      def teacher_ids_for_role(role)
        case role
        when "ect"
          teacher_ids_for_ect_role
        when "mentor"
          Teacher.unscoped.joins(:mentor_at_school_periods).distinct
        else
          Teacher.unscoped.none
        end
      end

      def teacher_ids_for_ect_role
        scope = Teacher.unscoped.left_outer_joins(:ect_at_school_periods, :induction_periods)

        scope
          .where.not(ect_at_school_periods: { id: nil })
          .or(scope.where.not(induction_periods: { id: nil }))
          .distinct
      end

      def contract_period_filter_clauses
        case role
        when "ect"
          [latest_ect_contract_period_matches_sql]
        when "mentor"
          [latest_mentor_contract_period_matches_sql]
        else
          clauses = [latest_ect_contract_period_matches_sql, latest_mentor_contract_period_matches_sql]
          clauses << no_role_assigned_sql if contract_period_not_available_filter?
          clauses
        end
      end

      def latest_ect_contract_period_matches_sql
        latest_ect_role_period_id_sql = latest_role_period_id_sql("ect_at_school_periods")

        chosen_schedule_id_sql = latest_training_attribute_sql(
          foreign_key: "ect_at_school_period_id",
          latest_role_period_id_sql: latest_ect_role_period_id_sql,
          attribute: "schedule_id"
        )

        if contract_period_not_available_filter?
          <<~SQL.squish
            (
              #{latest_ect_role_period_id_sql} IS NOT NULL
              OR EXISTS (
                SELECT 1
                FROM induction_periods
                WHERE induction_periods.teacher_id = teachers.id
              )
            )
            AND #{chosen_schedule_id_sql} IS NULL
          SQL
        else
          <<~SQL.squish
            EXISTS (
              SELECT 1
              FROM schedules
              WHERE schedules.id = #{chosen_schedule_id_sql}
                AND schedules.contract_period_year::text = :contract_period
            )
          SQL
        end
      end

      def latest_mentor_contract_period_matches_sql
        latest_mentor_role_period_id_sql = latest_role_period_id_sql("mentor_at_school_periods")

        chosen_schedule_id_sql = latest_training_attribute_sql(
          foreign_key: "mentor_at_school_period_id",
          latest_role_period_id_sql: latest_mentor_role_period_id_sql,
          attribute: "schedule_id"
        )

        if contract_period_not_available_filter?
          <<~SQL.squish
            #{latest_mentor_role_period_id_sql} IS NOT NULL
            AND #{chosen_schedule_id_sql} IS NULL
          SQL
        else
          <<~SQL.squish
            EXISTS (
              SELECT 1
              FROM schedules
              WHERE schedules.id = #{chosen_schedule_id_sql}
                AND schedules.contract_period_year::text = :contract_period
            )
          SQL
        end
      end

      def no_role_assigned_sql
        <<~SQL.squish
          NOT EXISTS (
            SELECT 1
            FROM ect_at_school_periods
            WHERE ect_at_school_periods.teacher_id = teachers.id
          )
          AND NOT EXISTS (
            SELECT 1
            FROM induction_periods
            WHERE induction_periods.teacher_id = teachers.id
          )
          AND NOT EXISTS (
            SELECT 1
            FROM mentor_at_school_periods
            WHERE mentor_at_school_periods.teacher_id = teachers.id
          )
        SQL
      end

      def contract_period_not_available_filter?
        contract_period == Rows::CONTRACT_PERIOD_NOT_AVAILABLE
      end

      def latest_role_period_id_sql(table_name)
        <<~SQL.squish
          (
            SELECT #{table_name}.id
            FROM #{table_name}
            WHERE #{table_name}.teacher_id = teachers.id
            ORDER BY #{latest_first_order_sql(table_name)}
            LIMIT 1
          )
        SQL
      end

      def latest_training_attribute_sql(foreign_key:, latest_role_period_id_sql:, attribute:)
        <<~SQL.squish
          (
            SELECT training_periods.#{attribute}
            FROM training_periods
            WHERE training_periods.#{foreign_key} = #{latest_role_period_id_sql}
            ORDER BY #{latest_first_order_sql('training_periods')}
            LIMIT 1
          )
        SQL
      end

      def latest_first_order_sql(table_name)
        <<~SQL.squish
          #{table_name}.started_on DESC,
          #{table_name}.id DESC
        SQL
      end

      def training_period_preload
        {
          latest_training_period: :schedule
        }
      end
    end
  end
end
