module BlazerQueries
  # Only GIAS::Reconciliation::Close records a school_closed event, and it refuses
  # to run while the school has any successor link. Therefore, any successor link on
  # a school with that event arrived after we had already finished or deleted its
  # teachers' periods.
  class PostClosureSchoolLinks
    SCHOOLS_QUERY_NAME = "GIAS: Schools closed without a link that gained one later"
    TEACHERS_QUERY_NAME = "GIAS: Teachers affected by a school link added after closure"

    class << self
      def sync!
        definitions.map do |definition|
          query = Blazer::Query.find_or_initialize_by(name: definition[:name])
          query.update!(
            description: definition[:description],
            statement: definition[:statement],
            data_source: :main,
            status: "active"
          )
          query
        end
      end

      def definitions
        [affected_schools, affected_teachers]
      end

    private

      delegate :quote, to: "ActiveRecord::Base.connection", private: true

      def affected_schools
        {
          name: SCHOOLS_QUERY_NAME,
          description: "Schools that RECT closed because GIAS gave us no successor " \
                       "link, where GIAS has since given a successor link to, and that " \
                       "had ECTs or mentors registered when they closed. Those " \
                       "teachers had their periods finished or deleted instead of " \
                       "being moved to the linked school. Row per closed school & link.",
          statement: <<~SQL.strip
            #{common_ctes}
            SELECT
              l.urn AS closed_school_urn,
              l.school_name AS closed_school_name,
              l.closed_on,
              l.closure_processed_at,
              l.link_type,
              l.link_urn,
              l.link_school_name,
              l.link_school_status,
              l.link_school_registered_in_rect,
              l.link_date AS link_established_on_in_gias,
              l.link_first_imported_at,
              l.link_last_changed_at,
              l.days_between_closure_and_link,
              counts.teachers_affected,
              counts.ect_periods_affected,
              counts.mentor_periods_affected,
              counts.teachers_registered_elsewhere_since,
              counts.teachers_registered_at_linked_school_since
            FROM late_links l
            INNER JOIN LATERAL (
              SELECT
                COUNT(DISTINCT a.teacher_id) AS teachers_affected,
                COUNT(*) FILTER (WHERE a.role = 'ECT') AS ect_periods_affected,
                COUNT(*) FILTER (WHERE a.role = 'Mentor') AS mentor_periods_affected,
                COUNT(DISTINCT a.teacher_id) FILTER (
                  WHERE #{registered_elsewhere_since_sql}
                ) AS teachers_registered_elsewhere_since,
                COUNT(DISTINCT a.teacher_id) FILTER (
                  WHERE #{registered_at_linked_school_since_sql}
                ) AS teachers_registered_at_linked_school_since
              FROM affected a
              WHERE a.closure_event_id = l.closure_event_id
            ) counts ON counts.teachers_affected > 0
            ORDER BY l.link_first_imported_at DESC, l.urn;
          SQL
        }
      end

      def affected_teachers
        {
          name: TEACHERS_QUERY_NAME,
          description: "The teachers behind '#{SCHOOLS_QUERY_NAME}'. One row per " \
                       "ECT or mentor period that RECT finished or deleted when we " \
                       "closed a school GIAS has since linked to a successor. " \
                       "'registered_elsewhere_since' and " \
                       "'registered_at_linked_school_since' flag teachers who have " \
                       "already been registered again (at any other school / at the " \
                       "linked school) on or after the closure date, so they " \
                       "probably need no further action.",
          statement: <<~SQL.strip
            #{common_ctes}
            SELECT
              l.urn AS closed_school_urn,
              l.school_name AS closed_school_name,
              l.closed_on,
              l.link_type,
              l.link_urn,
              l.link_school_name,
              l.link_school_status,
              l.link_school_registered_in_rect,
              l.days_between_closure_and_link,
              a.role,
              a.teacher_id,
              t.trn,
              #{teacher_name_sql} AS teacher_name,
              a.what_happened,
              a.started_on AS period_started_on,
              a.finished_on AS period_finished_on,
              #{registered_elsewhere_since_sql} AS registered_elsewhere_since,
              #{registered_at_linked_school_since_sql} AS registered_at_linked_school_since
            FROM late_links l
            INNER JOIN affected a ON a.closure_event_id = l.closure_event_id
            INNER JOIN teachers t ON t.id = a.teacher_id
            ORDER BY l.link_first_imported_at DESC, l.urn, a.role, a.teacher_id;
          SQL
        }
      end

      def common_ctes
        <<~SQL.strip
          WITH #{closures_cte},
          #{late_links_cte},
          #{affected_cte}
        SQL
      end

      def closures_cte
        <<~SQL.strip
          closures AS (
            SELECT
              e.id AS closure_event_id,
              e.school_id,
              (e.metadata ->> 'gias_school_urn')::integer AS urn,
              e.metadata ->> 'gias_school_name' AS school_name,
              e.created_at AS closure_processed_at
            FROM events e
            WHERE e.event_type = 'school_closed'
          )
        SQL
      end

      def late_links_cte
        <<~SQL.strip
          late_links AS (
            SELECT
              c.closure_event_id,
              c.school_id,
              c.urn,
              c.school_name,
              c.closure_processed_at,
              gs.closed_on,
              ls.link_type,
              ls.link_urn,
              ls.link_date,
              ls.created_at AS link_first_imported_at,
              ls.updated_at AS link_last_changed_at,
              #{london_date_sql('ls.created_at')} - gs.closed_on AS days_between_closure_and_link,
              lgs.name AS link_school_name,
              lgs.status::text AS link_school_status,
              (lrs.id IS NOT NULL) AS link_school_registered_in_rect
            FROM closures c
            INNER JOIN gias_schools gs ON gs.urn = c.urn
            INNER JOIN gias_school_links ls
              ON ls.urn = c.urn
             AND ls.link_type IN (#{successor_link_types_sql})
            LEFT JOIN gias_schools lgs ON lgs.urn = ls.link_urn
            LEFT JOIN schools lrs ON lrs.urn = ls.link_urn
          )
        SQL
      end

      # Close finishes ongoing periods on the closure date and destroys unstarted
      # ones, which leaves nothing behind but the deletion event.
      def affected_cte
        <<~SQL.strip
          affected AS (
            #{finished_periods_sql('ECT', 'ect_at_school_periods')}
            UNION ALL
            #{finished_periods_sql('Mentor', 'mentor_at_school_periods')}
            UNION ALL
            #{deleted_periods_sql('ECT', 'teacher_ect_at_school_period_deleted')}
            UNION ALL
            #{deleted_periods_sql('Mentor', 'teacher_mentor_at_school_period_deleted')}
          )
        SQL
      end

      def finished_periods_sql(role, table)
        <<~SQL.strip
          SELECT
              c.closure_event_id,
              c.school_id,
              gs.closed_on,
              #{quote(role)} AS role,
              p.teacher_id,
              p.started_on,
              p.finished_on,
              'period finished on the closure date' AS what_happened
            FROM closures c
            INNER JOIN gias_schools gs ON gs.urn = c.urn
            INNER JOIN #{table} p
              ON p.school_id = c.school_id
             AND p.finished_on = gs.closed_on
        SQL
      end

      def deleted_periods_sql(role, event_type)
        <<~SQL.strip
          SELECT
              c.closure_event_id,
              c.school_id,
              gs.closed_on,
              #{quote(role)} AS role,
              e.teacher_id,
              NULL::date AS started_on,
              NULL::date AS finished_on,
              'period deleted before it started' AS what_happened
            FROM closures c
            INNER JOIN gias_schools gs ON gs.urn = c.urn
            INNER JOIN events e
              ON e.school_id = c.school_id
             AND e.event_type = #{quote(event_type)}
             AND e.author_type = 'system'
             AND e.teacher_id IS NOT NULL
             AND #{london_date_sql('e.happened_at')} = gs.closed_on
        SQL
      end

      def registered_elsewhere_since_sql
        <<~SQL.strip
          EXISTS (
                SELECT 1 FROM ect_at_school_periods x
                WHERE x.teacher_id = a.teacher_id
                  AND x.school_id <> a.school_id
                  AND x.started_on >= a.closed_on
                UNION ALL
                SELECT 1 FROM mentor_at_school_periods x
                WHERE x.teacher_id = a.teacher_id
                  AND x.school_id <> a.school_id
                  AND x.started_on >= a.closed_on
              )
        SQL
      end

      def registered_at_linked_school_since_sql
        <<~SQL.strip
          EXISTS (
                SELECT 1 FROM ect_at_school_periods x
                INNER JOIN schools xs ON xs.id = x.school_id
                WHERE x.teacher_id = a.teacher_id
                  AND xs.urn = l.link_urn
                  AND x.started_on >= a.closed_on
                UNION ALL
                SELECT 1 FROM mentor_at_school_periods x
                INNER JOIN schools xs ON xs.id = x.school_id
                WHERE x.teacher_id = a.teacher_id
                  AND xs.urn = l.link_urn
                  AND x.started_on >= a.closed_on
              )
        SQL
      end

      # mirrors Teachers::Name#full_name
      def teacher_name_sql
        "COALESCE(NULLIF(t.corrected_name, ''), " \
          "NULLIF(TRIM(CONCAT_WS(' ', NULLIF(t.trs_first_name, '.'), NULLIF(t.trs_last_name, '.'))), ''), " \
          "'Unknown')"
      end

      # mirrors the successors check in GIAS::Reconciliation::Eligibility#can_be_closed?
      def successor_link_types_sql
        GIAS::SchoolLink::SUCCESSOR_LINK_TYPES.map { quote it }.join(", ")
      end

      # Timestamps are stored naively in UTC, so a bare cast to date lands a day
      # early on anything written during BST.
      def london_date_sql(column)
        "((#{column} AT TIME ZONE 'UTC') AT TIME ZONE 'Europe/London')::date"
      end
    end
  end
end
