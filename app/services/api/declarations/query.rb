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
          training_period: [
            { ect_at_school_period: :teacher },
            { mentor_at_school_period: :teacher },
            :delivery_partner,
            :lead_provider,
          ]
        )
    end

    def where_lead_provider_is(lead_provider_id)
      return if ignore?(filter: lead_provider_id)

      # Direct declarations - submitted by the lead provider
      direct_sql = <<~SQL.squish
        EXISTS (
          SELECT 1 FROM training_periods
          JOIN school_partnerships ON school_partnerships.id = training_periods.school_partnership_id
          JOIN lead_provider_delivery_partnerships ON lead_provider_delivery_partnerships.id = school_partnerships.lead_provider_delivery_partnership_id
          JOIN active_lead_providers ON active_lead_providers.id = lead_provider_delivery_partnerships.active_lead_provider_id
          WHERE training_periods.id = declarations.training_period_id
          AND active_lead_providers.lead_provider_id = :lead_provider_id
        )
      SQL

      # Previous declarations - for teachers who have a training period with this lead provider
      previous_sql = <<~SQL.squish
        EXISTS (
          SELECT 1 FROM training_periods tp
          JOIN school_partnerships sp ON sp.id = tp.school_partnership_id
          JOIN lead_provider_delivery_partnerships lpdp ON lpdp.id = sp.lead_provider_delivery_partnership_id
          JOIN active_lead_providers alp ON alp.id = lpdp.active_lead_provider_id
          LEFT JOIN ect_at_school_periods ect ON ect.id = tp.ect_at_school_period_id
          LEFT JOIN mentor_at_school_periods mentor ON mentor.id = tp.mentor_at_school_period_id
          JOIN training_periods decl_tp ON decl_tp.id = declarations.training_period_id
          LEFT JOIN ect_at_school_periods decl_ect ON decl_ect.id = decl_tp.ect_at_school_period_id
          LEFT JOIN mentor_at_school_periods decl_mentor ON decl_mentor.id = decl_tp.mentor_at_school_period_id
          WHERE alp.lead_provider_id = :lead_provider_id
          AND (
            COALESCE(ect.teacher_id, mentor.teacher_id) = COALESCE(decl_ect.teacher_id, decl_mentor.teacher_id)
          )
          AND (tp.finished_on IS NULL OR declarations.declaration_date <= tp.finished_on)
        )
        AND declarations.payment_status IN ('no_payment', 'eligible', 'payable', 'paid')
      SQL

      @scope = scope.where("(#{direct_sql}) OR (#{previous_sql})", lead_provider_id:)
    end

    def where_contract_period_year_in(contract_period_years)
      return if ignore?(filter: contract_period_years, ignore_empty_array: false)

      @scope = scope
        .joins(:contract_period)
        .where(contract_period: { year: contract_period_years })
    end

    def where_teacher_is(teacher_api_ids)
      return if ignore?(filter: teacher_api_ids)

      ect_join = scope
        .left_outer_joins(training_period: { ect_at_school_period: :teacher, mentor_at_school_period: :teacher })
        .where(teachers_ect_at_school_periods: { api_id: teacher_api_ids })

      mentor_join = scope
        .left_outer_joins(training_period: { ect_at_school_period: :teacher, mentor_at_school_period: :teacher })
        .where(teachers_mentor_at_school_periods: { api_id: teacher_api_ids })

      @scope = ect_join.or(mentor_join)
    end

    def where_delivery_partner_is(delivery_partner_api_ids)
      return if ignore?(filter: delivery_partner_api_ids)

      @scope = scope
        .joins(:delivery_partner)
        .where(delivery_partners: { api_id: delivery_partner_api_ids })
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      @scope = scope.where(updated_at: updated_since..)
    end
  end
end
