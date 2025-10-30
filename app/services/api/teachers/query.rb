module API::Teachers
  class Query
    include Queries::FilterIgnorable

    attr_reader :scope, :lead_provider_id

    def initialize(
      lead_provider_id: :ignore,
      contract_period_years: :ignore,
      training_status: :ignore,
      api_from_teacher_id: :ignore,
      updated_since: :ignore,
      sort: { created_at: :asc }
    )
      @lead_provider_id = lead_provider_id
      @scope = Teacher.distinct

      where_lead_provider_is(lead_provider_id)
      where_contract_period_year_in(contract_period_years)
      where_training_status_is(training_status)
      where_api_from_teacher_id_is(api_from_teacher_id)
      where_updated_since(updated_since)
      set_sort_by(sort)
    end

    def teachers
      preload_associations(block_given? ? yield(scope) : scope)
    end

    def teacher_by_api_id(api_id)
      return preload_associations(scope).find_by!(api_id:) if api_id.present?

      fail(ArgumentError, "api_id needed")
    end

    def teacher_by_id(id)
      return preload_associations(scope).find(id) if id.present?

      fail(ArgumentError, "id needed")
    end

  private

    def preload_associations(results)
      results
        .strict_loading
        .includes(
          :teacher_id_changes,
          :started_induction_period,
          :finished_induction_period,
          :earliest_ect_at_school_period,
          :earliest_mentor_at_school_period,
          lead_provider_metadata: {
            latest_ect_training_period: {
              school_partnership: [
                :school,
                { lead_provider_delivery_partnership: :delivery_partner }
              ],
              ect_at_school_period: [],
              schedule: []
            },
            latest_mentor_training_period: {
              school_partnership: [
                :school,
                { lead_provider_delivery_partnership: :delivery_partner }
              ],
              mentor_at_school_period: [],
              schedule: []
            }
          }
        )
    end

    def where_lead_provider_is(lead_provider_id)
      return if ignore?(filter: lead_provider_id)

      @scope = scope
        .joins(:lead_provider_metadata)
        .where(lead_provider_metadata: { lead_provider_id: })
        # Metadata exists for all lead provider/teacher combinations, but when
        # filtering by lead provider we only want teachers who have a training period
        # with that lead provider.
        .where.not(
          lead_provider_metadata: {
            latest_ect_training_period: nil,
            latest_mentor_training_period: nil
          }
        )
    end

    def where_contract_period_year_in(contract_period_years)
      return if ignore?(filter: contract_period_years, ignore_empty_array: false)

      @scope = scope.joins(:lead_provider_metadata)
      ect_contract_period_scope = @scope.where(lead_provider_metadata: { latest_ect_contract_period_year: contract_period_years })
      mentor_contract_period_scope = @scope.where(lead_provider_metadata: { latest_mentor_contract_period_year: contract_period_years })

      @scope = scope.merge(ect_contract_period_scope.or(mentor_contract_period_scope))
    end

    def where_training_status_is(training_status)
      return if ignore?(filter: training_status)

      @scope = scope
          .left_joins(
            lead_provider_metadata: %i[latest_ect_training_period latest_mentor_training_period]
          )

      # The latest_ect_training_period is joined as training_period and
      # latest_mentor_training_period as latest_mentor_training_periods_metadata_teachers_lead_providers
      # (using the alias names Rails creates for the join tables).
      @scope = case training_status.to_sym
               when :withdrawn
                 scope.where(
                   "training_periods.withdrawn_at IS NOT NULL
            OR latest_mentor_training_periods_metadata_teachers_lead_providers.withdrawn_at IS NOT NULL"
                 )
               when :deferred
                 scope.where(
                   "training_periods.deferred_at IS NOT NULL
            OR latest_mentor_training_periods_metadata_teachers_lead_providers.deferred_at IS NOT NULL"
                 )
               when :active
                 scope.where(
                   "(training_periods.id IS NOT NULL AND training_periods.withdrawn_at IS NULL AND training_periods.deferred_at IS NULL)
            OR (latest_mentor_training_periods_metadata_teachers_lead_providers.id IS NOT NULL AND
            latest_mentor_training_periods_metadata_teachers_lead_providers.deferred_at IS NULL AND
            latest_mentor_training_periods_metadata_teachers_lead_providers.withdrawn_at IS NULL)"
                 )
               else
                 Teacher.none
               end
    end

    def where_api_from_teacher_id_is(api_from_teacher_id)
      return if ignore?(filter: api_from_teacher_id)

      @scope = scope
        .joins(:teacher_id_changes)
        .where(teacher_id_changes: { api_from_teacher_id: })
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      # TODO: update when we have an accurate updated_at field
      @scope = scope.where(updated_at: updated_since..)
    end

    def set_sort_by(sort)
      @scope = scope.order(sort)
    end
  end
end
