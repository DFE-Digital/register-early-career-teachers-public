module Schools
  class Query
    include Queries::ConditionFormats
    include FilterIgnorable
    include QueryOrderable

    attr_reader :scope, :sort

    def initialize(lead_provider_id: :ignore, urn: :ignore, updated_since: :ignore, contract_period_id: :ignore, sort: nil)
      @scope = default_scope(contract_period_id).select(
        "schools.*",
        transient_in_partnership(contract_period_id),
        transient_mentors_at_school(contract_period_id),
        transient_ects_at_school_training_programme(contract_period_id),
        transient_expression_of_interest(lead_provider_id, contract_period_id)
      ).or(schools_with_existing_partnerships(contract_period_id))
            .or(schools_with_expression_of_interests(lead_provider_id, contract_period_id))
            .distinct

      @sort = sort

      where_urn_is(urn)
      where_updated_since(updated_since)
    end

    def schools
      scope.order(order_by)
    end

    def school_by_api_id(api_id)
      return scope.find_by!(gias_school: { api_id: }) if api_id.present?

      fail(ArgumentError, "api_id needed")
    end

    def school(id)
      return scope.find(id) if id.present?

      fail(ArgumentError, "id needed")
    end

  private

    def schools_with_existing_partnerships(contract_period_id)
      School.where(id: School.select("schools.id")
        .joins(school_partnerships: { lead_provider_delivery_partnership: { active_lead_provider: :contract_period } })
        .where(contract_periods: { year: contract_period_id }))
    end

    def schools_with_expression_of_interests(lead_provider_id, contract_period_id)
      return School.none if ignore?(filter: lead_provider_id) ||
        lead_provider_id.blank? ||
        ignore?(filter: contract_period_id) ||
        contract_period_id.blank?

      schools_with_ects_expressions_of_interest = School.select("schools.id")
        .joins(ect_at_school_periods: { training_periods: { expression_of_interest: :contract_period } })
        .where(contract_periods: { year: contract_period_id })
        .where(expression_of_interest: { lead_provider_id: })
        .group("schools.id")

      schools_with_mentors_expressions_of_interest = School.select("schools.id")
        .joins(mentor_at_school_periods: { training_periods: { expression_of_interest: :contract_period } })
        .where(contract_periods: { year: contract_period_id })
        .where(expression_of_interest: { lead_provider_id: })
        .group("schools.id")

      School.where(id: schools_with_ects_expressions_of_interest + schools_with_mentors_expressions_of_interest)
    end

    def where_urn_is(urn)
      return if ignore?(filter: urn)

      scope.merge!(School.where(urn:))
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      scope.merge!(School.where(updated_at: updated_since..))
    end

    def transient_in_partnership(contract_period_id)
      "EXISTS(
        #{
          School.select('1 AS one').from('schools s')
          .joins(school_partnerships: { lead_provider_delivery_partnership: { active_lead_provider: :contract_period } })
          .where(contract_periods: { year: contract_period_id })
          .where('schools.id = s.id')
          .limit(1)
          .to_sql
        }
      ) AS transient_in_partnership"
    end

    def transient_mentors_at_school(contract_period_id)
      return School.none if ignore?(filter: contract_period_id) || contract_period_id.blank?

      "EXISTS(
        #{
          School.select('1 AS one').from('schools s')
          .left_joins(mentor_at_school_periods: { training_periods: { expression_of_interest: :contract_period } })
          .left_joins(mentor_at_school_periods: { training_periods: { active_lead_provider: :contract_period } })
          .where('contract_periods.year = ? OR contract_periods_active_lead_providers.year = ?', contract_period_id, contract_period_id)
          .where('schools.id = s.id')
          .limit(1)
          .to_sql
        }
      ) AS transient_mentors_at_school"
    end

    def transient_ects_at_school_training_programme(contract_period_id)
      return School.none if ignore?(filter: contract_period_id) || contract_period_id.blank?

      "(
        #{
          School.distinct.select('ect_at_school_periods.training_programme').from('schools s')
          .left_joins(ect_at_school_periods: { training_periods: { expression_of_interest: :contract_period } })
          .left_joins(ect_at_school_periods: { training_periods: { active_lead_provider: :contract_period } })
          .where('contract_periods.year = ? OR contract_periods_active_lead_providers.year = ?', contract_period_id, contract_period_id)
          .where('schools.id = s.id')
          .order(training_programme: :asc)
          .limit(1)
          .to_sql
        }
      ) AS transient_ects_at_school_training_programme"
    end

    def transient_expression_of_interest(lead_provider_id, contract_period_id)
      return School.none if ignore?(filter: lead_provider_id) ||
        lead_provider_id.blank? ||
        ignore?(filter: contract_period_id) ||
        contract_period_id.blank?

      mentors_eoi = School.select('1 AS one').from('schools s')
                  .joins(mentor_at_school_periods: { training_periods: { expression_of_interest: :contract_period } })
                  .where(contract_periods: { year: contract_period_id })
                  .where(expression_of_interest: { lead_provider_id: })
                  .where('schools.id = s.id')
                  .limit(1)
                  .to_sql

      ects_eoi = School.select('1 AS one').from('schools s')
                  .joins(ect_at_school_periods: { training_periods: { expression_of_interest: :contract_period } })
                  .where(contract_periods: { year: contract_period_id })
                  .where(expression_of_interest: { lead_provider_id: })
                  .where('schools.id = s.id')
                  .limit(1)
                  .to_sql

      "CASE
            WHEN EXISTS (
               #{mentors_eoi}
            )
            THEN true
            WHEN EXISTS (
               #{ects_eoi}
            )
            THEN true
            ELSE false
        END AS transient_expression_of_interest"
    end

    def default_scope(contract_period_id)
      return School.none if ignore?(filter: contract_period_id) || contract_period_id.blank?

      School.eligible
        .eager_load(:gias_school)
    end

    def order_by
      sort_order(sort:, model: School, default: { created_at: :asc })
    end
  end
end
