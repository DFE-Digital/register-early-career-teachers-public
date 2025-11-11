module API::UnfundedMentors
  class Query
    include Queries::FilterIgnorable

    attr_reader :scope, :lead_provider_id

    def initialize(
      lead_provider_id: :ignore,
      updated_since: :ignore,
      sort: { created_at: :asc }
    )
      @lead_provider_id = lead_provider_id
      @scope = Teacher.distinct

      where_lead_provider_is(lead_provider_id)
      where_updated_since(updated_since)
      set_sort_by(sort)
    end

    def unfunded_mentors
      preload_associations(block_given? ? yield(scope) : scope)
    end

    def unfunded_mentor_by_api_id(api_id)
      return preload_associations(scope).find_by!(api_id:) if api_id.present?

      fail(ArgumentError, "api_id needed")
    end

    def unfunded_mentor_by_id(id)
      return preload_associations(scope).find(id) if id.present?

      fail(ArgumentError, "id needed")
    end

  private

    def preload_associations(results)
      # Joining with `mentor_at_school_periods`
      # In case we don't filter by lead provider
      # We still want to return only mentors
      results
        .strict_loading
        .joins(:mentor_at_school_periods)
        .includes(
          :latest_mentor_at_school_period
        )
    end

    def where_lead_provider_is(lead_provider_id)
      return if ignore?(filter: lead_provider_id)

      mentor_ids_associated_with_teachers_for_the_lead_provider = Metadata::TeacherLeadProvider
        .where(lead_provider_id:)
        .where.not(api_mentor_id: nil)
        .select(:api_mentor_id)

      mentor_ids_where_the_mentor_has_also_been_trained_by_the_lead_provider = Teacher
        .joins(lead_provider_metadata: :latest_mentor_training_period)
        .where(lead_provider_metadata: { lead_provider_id: })
        .select(:api_id)

      @scope = scope
        .where(api_id: mentor_ids_associated_with_teachers_for_the_lead_provider)
        .where.not(api_id: mentor_ids_where_the_mentor_has_also_been_trained_by_the_lead_provider)
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      @scope = scope.where(api_updated_at: updated_since..)
    end

    def set_sort_by(sort)
      @scope = scope.order(sort)
    end
  end
end
