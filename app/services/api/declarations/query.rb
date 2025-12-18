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
          mentorship_period: { mentor: :teacher },
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

      # Direct declarations: training period belongs to this lead provider
      direct_scope = scope
        .joins(training_period: :lead_provider)
        .where(lead_providers: { id: lead_provider_id })

      # Previous declarations: teachers who trained with this LP (with date/status constraints)
      previous_scope = previous_declarations_for_lead_provider(lead_provider_id)

      @scope = scope.where(id: direct_scope.select(:id)).or(scope.where(id: previous_scope.select(:id)))
    end

    def previous_declarations_for_lead_provider(lead_provider_id)
      previous_training_periods = TrainingPeriod
        .joins(:lead_provider)
        .left_joins(:ect_at_school_period, :mentor_at_school_period)
        .joins("INNER JOIN training_periods declaration_tp ON declaration_tp.id = declarations.training_period_id")
        .joins("LEFT OUTER JOIN ect_at_school_periods declaration_ect ON declaration_ect.id = declaration_tp.ect_at_school_period_id")
        .joins("LEFT OUTER JOIN mentor_at_school_periods declaration_mentor ON declaration_mentor.id = declaration_tp.mentor_at_school_period_id")
        .where(lead_provider: { id: lead_provider_id })
        .where(
          <<~SQL
            (ect_at_school_periods.teacher_id IS NOT NULL AND declaration_ect.teacher_id = ect_at_school_periods.teacher_id)
              OR
            (mentor_at_school_periods.teacher_id IS NOT NULL AND declaration_mentor.teacher_id = mentor_at_school_periods.teacher_id)
          SQL
        )
        .where("training_periods.finished_on IS NULL OR declarations.declaration_date <= training_periods.finished_on")
        .select("1")

      scope
        .billable_or_changeable
        .where("EXISTS (#{previous_training_periods.to_sql})")
    end

    def where_contract_period_year_in(contract_period_years)
      return if ignore?(filter: contract_period_years, ignore_empty_array: false)

      @scope = scope
        .joins(:contract_period)
        .where(contract_period: { year: contract_period_years })
    end

    def where_teacher_is(teacher_api_ids)
      return if ignore?(filter: teacher_api_ids)

      ect_join = scope.left_outer_joins(:ect_teacher, :mentor_teacher).where(ect_teacher: { api_id: teacher_api_ids })
      mentor_join = scope.left_outer_joins(:ect_teacher, :mentor_teacher).where(mentor_teacher: { api_id: teacher_api_ids })

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
