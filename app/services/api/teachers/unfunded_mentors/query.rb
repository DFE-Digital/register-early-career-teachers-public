module API::Teachers::UnfundedMentors
  class Query
    include Queries::FilterIgnorable

    def initialize(
      lead_provider_id:,
      updated_since: :ignore,
      sort: { created_at: :asc },
      included_associations: []
    )
      @scope = Teacher.distinct
      @included_associations = included_associations

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

    attr_reader :scope, :included_associations

    def preload_associations(results)
      results
        .strict_loading
        .tap { it.includes!(*included_associations) if included_associations.present? }
    end

    def where_lead_provider_is(lead_provider_id)
      mentor_teacher_ids_for_the_lead_provider = Metadata::TeacherLeadProvider
        .joins(ect_assigned_mentor_latest_school_period: :teacher)
        .where(lead_provider_id:)
        .select(MentorAtSchoolPeriod.arel_table[:teacher_id])

      teacher_ids_trained_by_the_lead_provider = Metadata::TeacherLeadProvider
        .where(lead_provider_id:)
        .where.not(
          latest_ect_training_period: nil,
          latest_mentor_training_period: nil
        )
        .select(:teacher_id)

      @scope = scope
        .where(id: mentor_teacher_ids_for_the_lead_provider)
        .where.not(id: teacher_ids_trained_by_the_lead_provider)
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      @scope = scope.where(api_unfunded_mentor_updated_at: updated_since..)
    end

    def set_sort_by(sort)
      @scope = scope.order(sort)
    end
  end
end
