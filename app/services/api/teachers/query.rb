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
      include_withdrawn_by_error: true,
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
      preloaded_results = results
        .strict_loading
        .eager_load(
          :earliest_ect_at_school_period,
          :earliest_mentor_at_school_period,
          :teacher_id_changes,
          lead_provider_metadata: {
            latest_ect_training_period: {
              school_partnership: %i[
                school
                contract_period
                delivery_partner
              ],
              unscoped_ect_at_school_period: {
                teacher: %i[
                  started_induction_period
                  finished_induction_period
                ]
              }
            },
            latest_mentor_training_period: {
              school_partnership: %i[
                school
                contract_period
                delivery_partner
              ],
              unscoped_mentor_at_school_period: {
                teacher: %i[
                  started_induction_period
                  finished_induction_period
                ]
              }
            }
          }
        )

      unless ignore?(filter: lead_provider_id)
        preloaded_results = preloaded_results
          .references(:lead_provider_metadata)
          .where(lead_provider_metadata: { lead_provider_id: })
      end

      preloaded_results
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
      return if ignore?(filter: contract_period_years)

      @scope = scope
          .left_joins(
            lead_provider_metadata: {
              latest_ect_training_period: {
                school_partnership: {
                  lead_provider_delivery_partnership: :active_lead_provider
                }
              },
              latest_mentor_training_period: {
                school_partnership: {
                  lead_provider_delivery_partnership: :active_lead_provider
                }
              }
            }
          )
          .where(
            # The first where conditional is for ECTs and the second for mentors
            # (using the alias names Rails creates for the join tables).
            <<~SQL.squish,
              active_lead_providers.contract_period_year IN (:years)
              OR active_lead_providers_lead_provider_delivery_partnerships.contract_period_year IN (:years)
            SQL
            years: contract_period_years
          )
    end

    def where_training_status_is(training_status)
      nil if ignore?(filter: training_status)

      # TODO: implement when we have the training status field
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
