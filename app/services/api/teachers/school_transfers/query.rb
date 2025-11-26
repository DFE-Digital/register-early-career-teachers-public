module API::Teachers::SchoolTransfers
  class Query
    include Queries::FilterIgnorable

    attr_reader :scope

    def initialize(
      lead_provider_id:,
      updated_since: :ignore,
      sort: { created_at: :asc }
    )
      @scope = Teacher.distinct

      where_lead_provider_is(lead_provider_id)
      where_updated_since(updated_since)
      set_sort_by(sort)
    end

    def school_transfers
      preload_associations(block_given? ? yield(scope) : scope)
    end

    def school_transfers_by_api_id(api_id)
      return preload_associations(scope).find_by!(api_id:) if api_id.present?

      fail(ArgumentError, "api_id needed")
    end

    def school_transfers_by_id(id)
      return preload_associations(scope).find(id) if id.present?

      fail(ArgumentError, "id needed")
    end

  private

    def preload_associations(results)
      results
        .strict_loading
        .includes(
          lead_provider_metadata: [],
          finished_induction_period: [],
          ect_at_school_periods: {
            earliest_training_period: {
              school_partnership: :school,
              active_lead_provider: :lead_provider
            },
            latest_training_period: {
              school_partnership: :school,
              active_lead_provider: :lead_provider
            }
          },
          mentor_at_school_periods: {
            earliest_training_period: {
              school_partnership: :school,
              active_lead_provider: :lead_provider
            },
            latest_training_period: {
              school_partnership: :school,
              active_lead_provider: :lead_provider
            }
          }
        )
    end

    def where_lead_provider_is(lead_provider_id)
      @scope = scope
        .joins(:lead_provider_metadata)
        .where(
          lead_provider_metadata: {
            lead_provider_id:,
            involved_in_school_transfer: true
          }
        )
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      @scope = scope
          .left_joins(
            ect_at_school_periods: %i[earliest_training_period latest_training_period],
            mentor_at_school_periods: %i[earliest_training_period latest_training_period]
          )
          .where(
            "(training_periods.id IS NOT NULL AND training_periods.api_transfer_updated_at >= :updated_since) OR
            (latest_training_periods_ect_at_school_periods.id IS NOT NULL AND latest_training_periods_ect_at_school_periods.api_transfer_updated_at >= :updated_since) OR
            (earliest_training_periods_mentor_at_school_periods.id IS NOT NULL AND earliest_training_periods_mentor_at_school_periods.api_transfer_updated_at >= :updated_since) OR
            (latest_training_periods_mentor_at_school_periods.id IS NOT NULL AND latest_training_periods_mentor_at_school_periods.api_transfer_updated_at >= :updated_since)",
            updated_since:
          )
    end

    def set_sort_by(sort)
      @scope = scope.order(sort)
    end
  end
end
