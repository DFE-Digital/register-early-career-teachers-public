module Admin
  module Teachers
    class Search
      def initialize(query_string: nil)
        @query_string = query_string.to_s.strip
      end

      def search
        matching(Teacher.unscoped)
      end

    private

      attr_reader :query_string

      def matching(scope)
        return scope if query_string.blank?

        trns = query_string.scan(/\b\d{7}\b/)
        return scope.where(trn: trns) if trns.any?

        full_text_scope = full_text_matches(scope)
        return full_text_scope unless api_participant_id_query?

        full_text_scope.or(api_participant_id_matches(scope))
      end

      def full_text_matches(scope)
        return scope.none if normalized_full_text_query.blank?

        scope.where(
          "teachers.search @@ to_tsquery('unaccented', ?)",
          FullTextSearch::Query.new(normalized_full_text_query).search_by_all_prefixes
        )
      end

      def normalized_full_text_query
        @normalized_full_text_query ||= query_string.scan(/[[:alnum:]]+/).join(" ")
      end

      def api_participant_id_query?
        query_string.match?(/\A(?=.*[\d-])[a-f0-9-]{8,}\z/i)
      end

      def api_participant_id_matches(scope)
        escaped_query = ActiveRecord::Base.sanitize_sql_like(query_string)

        scope.where("CAST(teachers.api_id AS text) ILIKE ?", "%#{escaped_query}%")
      end
    end
  end
end
