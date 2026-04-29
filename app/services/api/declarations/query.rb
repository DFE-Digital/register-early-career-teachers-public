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
      @scope = join_school_period(Declaration.order(:created_at))

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

      declarations_matching_lead_provider(lead_provider_id)
    end

    def declarations_matching_lead_provider(lead_provider_id)
      @scope = scope
        # Join the lead provider for the declaration.
        .joins(
          training_period: {
            school_partnership: {
              lead_provider_delivery_partnership: :active_lead_provider
            }
          }
        )
        # Join the metadata for the lead provider and teacher.
        .joins(
          ActiveRecord::Base.send(
            :sanitize_sql_array,
            [
              <<~SQL,
                JOIN metadata_teachers_lead_providers
                  ON metadata_teachers_lead_providers.lead_provider_id = ?
                AND (
                  metadata_teachers_lead_providers.teacher_id = CASE
                    WHEN ect_at_school_periods.id IS NOT NULL
                      THEN ect_at_school_periods.teacher_id
                    WHEN mentor_at_school_periods.id IS NOT NULL
                      THEN mentor_at_school_periods.teacher_id
                  END
                )
              SQL
              lead_provider_id
            ]
          )
        )
        # Join latest ECT/mentor training period for the lead provider; this will ensure that:
        #   * If the declaration is for an ECT, the ECT has been trained by the lead provider.
        #   * If the declaration is for a mentor, the mentor has been trained by the lead provider.
        .joins(<<~SQL)
          JOIN training_periods latest_training_period
            ON latest_training_period.id = CASE
              WHEN ect_at_school_periods.id IS NOT NULL
                THEN metadata_teachers_lead_providers.latest_ect_training_period_id
              WHEN mentor_at_school_periods.id IS NOT NULL
                THEN metadata_teachers_lead_providers.latest_mentor_training_period_id
            END
        SQL
        # Restrict to either:
        #   * Declarations directly associated with the lead provider.
        #   * Billable declarations dated earlier than the latest ECT/mentor training period for the lead provider.
        .where(<<-SQL, payment_statuses: Declaration::BILLABLE_OR_CHANGEABLE_PAYMENT_STATUSES, lead_provider_id:)
          active_lead_providers.lead_provider_id = :lead_provider_id
          OR (
            declarations.payment_status IN (:payment_statuses)
            AND declarations.clawback_status = 'no_clawback'
            AND (
              latest_training_period.finished_on IS NULL
              OR declarations.declaration_date <= latest_training_period.finished_on
            )
          )
        SQL
    end

    def join_school_period(scope)
      # Join the ECT or mentor school period (this will only ever be one or the other).
      scope
        .joins(:training_period)
        .left_joins(training_period: %i[ect_at_school_period mentor_at_school_period])
    end

    def where_contract_period_year_in(contract_period_years)
      return if ignore?(filter: contract_period_years, ignore_empty_array: false)

      @scope = scope
        .joins(:contract_period)
        .where(contract_period: { year: contract_period_years })
    end

    def where_teacher_is(teacher_api_ids)
      return if ignore?(filter: teacher_api_ids, ignore_empty_array: false)

      teacher_subquery = Teacher.where(api_id: teacher_api_ids).select(:id)
      @scope = scope
        .where(
          "ect_at_school_periods.teacher_id IN (:ids) OR mentor_at_school_periods.teacher_id IN (:ids)",
          ids: teacher_subquery
        )
    end

    def where_delivery_partner_is(delivery_partner_api_ids)
      return if ignore?(filter: delivery_partner_api_ids, ignore_empty_array: false)

      delivery_partner_subquery = DeliveryPartner.where(api_id: delivery_partner_api_ids).select(:id)
      @scope = scope.where(delivery_partner_when_created_id: delivery_partner_subquery)
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      @scope = scope.where(api_updated_at: updated_since..)
    end
  end
end
