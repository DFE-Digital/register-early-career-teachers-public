module Admin
  module Teachers
    class NameOrIdentifierSearch
      def initialize(query_string:)
        @query_string = query_string.to_s
      end

      def matching_teacher_scope
        matching(Teacher.unscoped)
      end

    private

      attr_reader :query_string

      def matching(scope)
        return scope if query_string.blank?

        trns = query_string.scan(/\b\d{7}\b/)
        return scope.where(trn: trns) if trns.any?

        api_ids = query_string.scan(/\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b/i)
        return api_id_matches(scope, api_ids) if api_ids.any?

        full_text_matches(scope)
      end

      def api_id_matches(scope, ids)
        scope.where(api_id: ids)
          .or(scope.where(api_ect_training_record_id: ids))
          .or(scope.where(api_mentor_training_record_id: ids))
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
    end
  end
end
