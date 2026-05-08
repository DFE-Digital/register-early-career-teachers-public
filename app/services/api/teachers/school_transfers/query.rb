module API::Teachers::SchoolTransfers
  class Query
    include Queries::FilterIgnorable

    attr_reader :scope, :lead_provider_id, :updated_since, :sort

    def initialize(
      lead_provider_id:,
      updated_since: :ignore,
      sort: { created_at: :asc }
    )
      @scope = Teacher.distinct
      @lead_provider_id = lead_provider_id
      @updated_since = updated_since
      @sort = sort

      where_lead_provider
      where_updated_since
      set_sort_by
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
          ect_at_school_periods: [
            :school,
            {
              earliest_training_period: :lead_provider,
              latest_training_period: :lead_provider
            }
          ],
          mentor_at_school_periods: [
            :school,
            {
              earliest_training_period: :lead_provider,
              latest_training_period: :lead_provider
            }
          ]
        )
    end

    def set_sort_by
      @scope = scope.order(sort)
    end

    def where_lead_provider
      @scope = scope
        .joins(:lead_provider_metadata)
        .where(
          lead_provider_metadata: {
            lead_provider_id:,
            involved_in_school_transfer: true
          }
        )
    end

    def teacher_ids
      @teacher_ids ||= scope.ids
    end

    def boundary_ect_at_school_periods
      ECTAtSchoolPeriod
        .where(teacher_id: teacher_ids)
        .includes(:earliest_training_period, :latest_training_period)
    end

    def boundary_mentor_at_school_periods
      MentorAtSchoolPeriod
        .where(teacher_id: teacher_ids)
        .includes(:earliest_training_period, :latest_training_period)
    end

    def boundary_training_period_ids
      [*boundary_ect_at_school_periods, *boundary_mentor_at_school_periods].flat_map { |at_school_period|
        [
          at_school_period.earliest_training_period&.id,
          at_school_period.latest_training_period&.id
        ]
      }.compact.uniq
    end

    def boundary_training_periods_updated_since
      @boundary_training_periods_updated_since ||=
        TrainingPeriod
          .joins(school_partnership: { lead_provider_delivery_partnership: :active_lead_provider })
          .where(active_lead_providers: { lead_provider_id: })
          .where(api_transfer_updated_at: updated_since..)
          .where(id: boundary_training_period_ids)
    end

    def ect_ids
      boundary_training_periods_updated_since
        .joins(:ect_at_school_period)
        .pluck("ect_at_school_periods.teacher_id")
    end

    def mentor_ids
      boundary_training_periods_updated_since
        .joins(:mentor_at_school_period)
        .pluck("mentor_at_school_periods.teacher_id")
    end

    # Filters scope to teachers with transfer-boundary training periods that were
    # updated since +updated_since+ for the given lead provider.
    #
    # A transfer boundary is defined as the FIRST or LAST training period in a
    # school period. Any interim period is never part of a transfer and must be
    # excluded.
    #
    def where_updated_since
      return if ignore?(filter: updated_since)

      @scope = scope.where(id: ect_ids + mentor_ids)
    end
  end
end
