module BlazerQueries
  class SchoolComms
    # Fallback to use with GIAS establishment contact email when no SIT is registered.
    HEADTEACHER_NAME_PLACEHOLDER = "colleague"

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
        [
          registrations_opening,
          start_of_term_september,
          start_of_term_january_april,
          partnership_without_participants
        ]
      end

    private

      delegate :quote, to: "ActiveRecord::Base.connection", private: true

      def registrations_opening
        {
          name: "Comms: Registrations opening (June)",
          description: "All eligible schools (excluding children's centres and " \
                       "linked sites)" \
                       "#{recipient_note}",
          statement: <<~SQL.strip
            SELECT
              s.urn,
              gs.name AS school_name,
              #{recipient_name_sql},
              #{recipient_email_sql},
              gs.type_name AS establishment_type,
              gs.phase_name AS phase,
              gs.section_41_approved,
              (
                SELECT r.code
                FROM regions r
                WHERE gs.administrative_district_name = ANY (r.districts)
                LIMIT 1
              ) AS region,
              (dsi.first_authenticated_at IS NOT NULL) AS previously_signed_into_rect,
              s.last_chosen_training_programme AS latest_training_programme,
              lp.name AS latest_lead_provider,
              #{opt_out_url_sql} AS reminder_email_opt_out_url
            FROM schools s
            INNER JOIN gias_schools gs ON gs.urn = s.urn
            LEFT JOIN lead_providers lp ON lp.id = s.last_chosen_lead_provider_id
            LEFT JOIN dfe_sign_in_organisations dsi ON dsi.urn = s.urn::text
            WHERE #{eligible_sql}
              AND #{not_a_childrens_centre_sql}
            ORDER BY gs.name;
          SQL
        }
      end

      def start_of_term_september
        {
          name: "Comms: Start of term reminder (September)",
          description: "All eligible schools (excluding children's centres and " \
                       "linked sites) that have NOT opted out of reminder emails" \
                       "#{recipient_note}",
          statement: <<~SQL.strip
            SELECT
              s.urn,
              gs.name AS school_name,
              #{recipient_name_sql},
              #{recipient_email_sql},
              #{opt_out_url_sql} AS reminder_email_opt_out_url
            FROM schools s
            INNER JOIN gias_schools gs ON gs.urn = s.urn
            WHERE #{eligible_sql}
              AND #{not_a_childrens_centre_sql}
              AND #{not_opted_out_sql}
            ORDER BY gs.name;
          SQL
        }
      end

      def start_of_term_january_april
        {
          name: "Comms: Start of term reminder (January / April)",
          description: "All eligible schools (excluding children's centres and " \
                       "linked sites). #{recipient_note}",
          statement: <<~SQL.strip
            SELECT
              s.urn,
              gs.name AS school_name,
              #{recipient_name_sql},
              #{recipient_email_sql},
              #{opt_out_url_sql} AS reminder_email_opt_out_url
            FROM schools s
            INNER JOIN gias_schools gs ON gs.urn = s.urn
            WHERE #{eligible_sql}
              AND #{not_a_childrens_centre_sql}
            ORDER BY gs.name;
          SQL
        }
      end

      def partnership_without_participants
        {
          name: "Comms: Partnership created but no ECTs or mentors follow-up",
          description: "Schools with a school partnership in the current contract " \
                       "period but no ECTs or mentors at the school, that have NOT " \
                       "opted out of reminder emails (children's centres and linked " \
                       "sites excluded). #{recipient_note}",
          statement: <<~SQL.strip
            SELECT
              s.urn,
              gs.name AS school_name,
              #{recipient_name_sql},
              #{recipient_email_sql},
              #{opt_out_url_sql} AS reminder_email_opt_out_url
            FROM schools s
            INNER JOIN gias_schools gs ON gs.urn = s.urn
            WHERE #{not_a_childrens_centre_sql}
              AND #{not_opted_out_sql}
              AND EXISTS (
                SELECT 1
                FROM school_partnerships sp
                INNER JOIN lead_provider_delivery_partnerships lpdp
                  ON lpdp.id = sp.lead_provider_delivery_partnership_id
                INNER JOIN active_lead_providers alp
                  ON alp.id = lpdp.active_lead_provider_id
                INNER JOIN contract_periods cp ON cp.year = alp.contract_period_year
                WHERE sp.school_id = s.id
                  AND cp.range @> CURRENT_DATE
              )
              AND NOT EXISTS (
                SELECT 1 FROM ect_at_school_periods e WHERE e.school_id = s.id
              )
              AND NOT EXISTS (
                SELECT 1 FROM mentor_at_school_periods m WHERE m.school_id = s.id
              )
            ORDER BY gs.name;
          SQL
        }
      end

      # mirrors School.eligible
      def eligible_sql
        "(s.marked_as_eligible OR gs.eligible)"
      end

      # #2501: never contact children's centres or their linked sites.
      def not_a_childrens_centre_sql
        list = GIAS::Types::CHILDRENS_CENTRE_TYPES.map { quote it }.join(", ")
        "gs.type_name NOT IN (#{list})"
      end

      def not_opted_out_sql
        "(s.opted_out_of_reminder_emails_until IS NULL " \
          "OR s.opted_out_of_reminder_emails_until < CURRENT_DATE)"
      end

      def recipient_name_sql
        "CASE WHEN s.induction_tutor_email IS NOT NULL " \
          "THEN s.induction_tutor_name " \
          "ELSE #{quote(HEADTEACHER_NAME_PLACEHOLDER)} END AS recipient_name"
      end

      def recipient_email_sql
        "COALESCE(s.induction_tutor_email::text, gs.primary_contact_email, " \
          "gs.secondary_contact_email) AS recipient_email"
      end

      def recipient_note
        "Falls back to the GIAS contact email and a '#{HEADTEACHER_NAME_PLACEHOLDER}' " \
          "placeholder name when a school has no registered SIT."
      end

      def opt_out_url_sql
        token_sql = Schools::ReminderEmailOptOutToken.token_sql(school_id_sql: "s.id")

        "'#{opt_out_base_url}?school_id=' || s.id || '&token=' || #{token_sql}"
      end

      def opt_out_base_url
        options = Rails.application.config.action_mailer.default_url_options || {}
        host = options[:host].presence
        raise "action_mailer default_url_options host is not configured" if host.blank?

        scheme = host == "localhost" ? "http" : "https"
        authority = [host, options[:port]].compact.join(":")
        path = Rails.application.routes.url_helpers.new_schools_reminder_email_opt_out_path

        "#{scheme}://#{authority}#{path}"
      end
    end
  end
end
