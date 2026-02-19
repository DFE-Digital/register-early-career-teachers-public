module API::Declarations
  class Query
    include Queries::FilterIgnorable

    attr_reader :scope, :lead_provider_id

    def initialize(
      lead_provider_id: :ignore,
      contract_period_years: :ignore,
      teacher_api_ids: :ignore,
      delivery_partner_api_ids: :ignore,
      updated_since: :ignore
    )
      @lead_provider_id = lead_provider_id
      @scope = Declaration.distinct

      where_lead_provider_is(lead_provider_id)
      where_contract_period_year_in(contract_period_years)
      where_teacher_is(teacher_api_ids)
      where_delivery_partner_is(delivery_partner_api_ids)
      where_updated_since(updated_since)
    end

    def declarations
      preload_associations(block_given? ? yield(scope) : scope)
    end

    def declaration_by_api_id(api_id)
      return preload_associations(scope).find_by!(api_id:) if api_id.present?

      fail(ArgumentError, "api_id needed")
    end

    def declaration_by_id(id)
      return preload_associations(scope).find(id) if id.present?

      fail(ArgumentError, "id needed")
    end

  private

    def preload_associations(results)
      results
        .strict_loading
        .includes(
          :payment_statement,
          :clawback_statement,
          :delivery_partner_when_created,
          mentorship_period: { mentor: :teacher },
          training_period: [
            { ect_at_school_period: :teacher },
            { mentor_at_school_period: :teacher },
            :lead_provider,
          ]
        )
    end

    def where_lead_provider_is(lead_provider_id)
      return if ignore?(filter: lead_provider_id)

      @scope = scope
        # Join the lead provider for the declaration.
        .joins(
          training_period: {
            school_partnership: {
              lead_provider_delivery_partnership: :active_lead_provider
            }
          }
        )
        # Join the ECT and mentor school periods (left join as its one or the other).
        .left_joins(training_period: %i[ect_at_school_period mentor_at_school_period])
        # Join the latest ECT and mentor training period for the lead provider we are filtering by.
        # This will restrict declarations to only those for teachers associated with the lead provider we are filtering by.
        # The manual sanitisation is needed as Rails does not support binding parameters in JOINs.
        .joins(
          ActiveRecord::Base.send(
            :sanitize_sql_array,
            [
              <<~SQL,
                JOIN metadata_teachers_lead_providers
                  ON metadata_teachers_lead_providers.lead_provider_id = ?
                AND (
                  (metadata_teachers_lead_providers.teacher_id = ect_at_school_periods.teacher_id
                    AND latest_ect_training_period_id IS NOT NULL)
                OR (metadata_teachers_lead_providers.teacher_id = mentor_at_school_periods.teacher_id
                    AND latest_mentor_training_period_id IS NOT NULL)
                )
              SQL
              lead_provider_id
            ]
          )
        )
        .joins(<<-SQL)
          LEFT JOIN training_periods latest_mentor_training_period
          ON latest_mentor_training_period.id = metadata_teachers_lead_providers.latest_mentor_training_period_id
        SQL
        .joins(<<-SQL)
          LEFT JOIN training_periods latest_ect_training_period ON
          latest_ect_training_period.id = metadata_teachers_lead_providers.latest_ect_training_period_id
        SQL
        # Restrict to either:
        #   * Declarations directly associated with the lead provider we are filtering by.
        #   * Billable declarations dated earlier than the latest ECT/mentor training period for the lead provider we are filtering by.
        .where(<<-SQL, payment_statuses: Declaration::BILLABLE_OR_CHANGEABLE_PAYMENT_STATUSES, lead_provider_id:)
          active_lead_providers.lead_provider_id = :lead_provider_id
          OR
          (
            (
              CASE
                WHEN ect_at_school_periods.id IS NOT NULL THEN
                  latest_ect_training_period.finished_on
                ELSE
                  latest_mentor_training_period.finished_on
              END IS NULL
              OR
              declarations.declaration_date <=
              CASE
                WHEN ect_at_school_periods.id IS NOT NULL THEN
                  latest_ect_training_period.finished_on
                ELSE
                  latest_mentor_training_period.finished_on
              END
            )
            AND declarations.payment_status IN (:payment_statuses)
            AND declarations.clawback_status = 'no_clawback'
          )
        SQL
    end

    def where_contract_period_year_in(contract_period_years)
      return if ignore?(filter: contract_period_years, ignore_empty_array: false)

      @scope = scope
        .joins(:contract_period)
        .where(contract_period: { year: contract_period_years })
    end

    def where_teacher_is(teacher_api_ids)
      return if ignore?(filter: teacher_api_ids, ignore_empty_array: false)

      ect_join = scope.left_outer_joins(:ect_teacher, :mentor_teacher).where(ect_teacher: { api_id: teacher_api_ids })
      mentor_join = scope.left_outer_joins(:ect_teacher, :mentor_teacher).where(mentor_teacher: { api_id: teacher_api_ids })

      @scope = ect_join.or(mentor_join)
    end

    def where_delivery_partner_is(delivery_partner_api_ids)
      return if ignore?(filter: delivery_partner_api_ids, ignore_empty_array: false)

      @scope = scope
        .joins(:delivery_partner_when_created)
        .where(delivery_partner_when_created: { api_id: delivery_partner_api_ids })
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      @scope = scope.where(updated_at: updated_since..)
    end
  end
end
