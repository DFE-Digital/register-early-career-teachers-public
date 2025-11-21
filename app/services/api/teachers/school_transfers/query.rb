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

  private

    def preload_associations(results)
      results
        .strict_loading
        .includes(
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
      # Retrieve all the "first" ECTAtSchoolPeriods for each teacher in a
      # subquery so we can exclude them
      first_ect_at_school_periods_subquery = ECTAtSchoolPeriod
        .select("DISTINCT ON (teacher_id) id")
        .order(:teacher_id, :started_on, :id)

      # Teachers with an ECTAtSchoolPeriod where the latest finished
      # training period is with the given lead provider
      latest_finished_ect_training_period_teachers = Teacher
        .joins(
          ect_at_school_periods: {
            earliest_training_period: :active_lead_provider,
            latest_training_period: :active_lead_provider
          }
        )
        .where(
          ect_at_school_periods: {
            latest_training_period: {
              active_lead_providers: { lead_provider_id: }
            }
          }
        )
        .where.not(ect_at_school_periods: { finished_on: nil })
        .where.not(
          ect_at_school_periods: {
            id: first_ect_at_school_periods_subquery
          }
        )
      # Teachers with an ECTAtSchoolPeriod where the earliest
      # training period is with the given lead provider
      earliest_ect_training_period_teachers = Teacher
        .joins(
          ect_at_school_periods: {
            earliest_training_period: :active_lead_provider,
            latest_training_period: :active_lead_provider
          }
        )
        .where(
          ect_at_school_periods: {
            earliest_training_period: {
              active_lead_providers: { lead_provider_id: }
            }
          }
        )
        .where.not(
          ect_at_school_periods: {
            id: first_ect_at_school_periods_subquery
          }
        )
      ect_ids = latest_finished_ect_training_period_teachers
        .or(earliest_ect_training_period_teachers)
        .pluck(:id)

      # Retrieve all the "first" MentorAtSchoolPeriods for each teacher in a
      # subquery so we can exclude them
      first_mentor_at_school_periods_subquery = MentorAtSchoolPeriod
        .select("DISTINCT ON (teacher_id) id")
        .order(:teacher_id, :started_on, :id)

      # Teachers with a MentorAtSchoolPeriod where the latest finished
      # training period is with the given lead provider
      latest_finished_mentor_training_period_teachers = Teacher
        .joins(
          mentor_at_school_periods: {
            earliest_training_period: :active_lead_provider,
            latest_training_period: :active_lead_provider
          }
        )
        .where(
          mentor_at_school_periods: {
            latest_training_period: {
              active_lead_providers: { lead_provider_id: }
            }
          }
        )
        .where.not(mentor_at_school_periods: { finished_on: nil })
        .where.not(
          mentor_at_school_periods: {
            id: first_mentor_at_school_periods_subquery
          }
        )
      # Teachers with a MentorAtSchoolPeriod where the earliest
      # training period is with the given lead provider
      earliest_mentor_training_period_teachers = Teacher
        .joins(
          mentor_at_school_periods: {
            earliest_training_period: :active_lead_provider,
            latest_training_period: :active_lead_provider
          }
        )
        .where(
          mentor_at_school_periods: {
            earliest_training_period: {
              active_lead_providers: { lead_provider_id: }
            }
          }
        )
        .where.not(
          mentor_at_school_periods: {
            id: first_mentor_at_school_periods_subquery
          }
        )
      mentor_ids = latest_finished_mentor_training_period_teachers
        .or(earliest_mentor_training_period_teachers)
        .pluck(:id)

      @scope = scope.where(id: ect_ids + mentor_ids)
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
