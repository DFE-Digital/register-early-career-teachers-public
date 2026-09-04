module API::MentorshipPeriods
  class Query
    include Queries::FilterIgnorable

    def initialize(
      lead_provider_id:,
      updated_since: :ignore,
      ect_api_id: :ignore,
      mentor_api_id: :ignore,
      school_urn: :ignore,
      sort: { created_at: :desc },
      included_associations: []
    )
      @scope = MentorshipPeriod.all
      @included_associations = included_associations

      where_lead_provider(lead_provider_id)
      where_updated_since(updated_since)
      where_ect_api_id(ect_api_id)
      where_mentor_api_id(mentor_api_id)
      where_school_urn(school_urn)
      set_sort_by(sort)
    end

    def mentorship_periods
      preload_associations(block_given? ? yield(scope) : scope)
    end

  private

    attr_reader :scope, :included_associations

    def preload_associations(results)
      results
        .strict_loading
        .tap { it.includes!(included_associations) if included_associations.present? }
    end

    def where_lead_provider(lead_provider_id)
      @scope = scope
        .joins(mentee: { training_periods: :lead_provider })
        .where(
          lead_providers: {
            id: lead_provider_id,
          }
        )
    end

    def where_updated_since(updated_since)
      return if updated_since == :ignore

      @scope = scope.where("mentorship_periods.updated_at >= ?", updated_since)
    end

    def where_ect_api_id(ect_api_id)
      return if ect_api_id == :ignore

      @scope = scope
        .joins(:ect_teacher)
        .where(ect_teacher: { api_ect_training_record_id: ect_api_id })
    end

    def where_mentor_api_id(mentor_api_id)
      return if mentor_api_id == :ignore

      @scope = scope
        .joins(:mentor_teacher)
        .where(mentor_teacher: { api_mentor_training_record_id: mentor_api_id })
    end

    def where_school_urn(school_urn)
      return if school_urn == :ignore

      @scope = scope
        .joins(mentee: :school)
        .where(schools: { urn: school_urn })
    end

    def set_sort_by(sort)
      @scope = scope.order(sort)
    end
  end
end
