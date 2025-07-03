module Schools
  class Query
    include Queries::ConditionFormats
    include FilterIgnorable

    attr_reader :scope, :contract_period_id

    def initialize(lead_provider: :ignore, urn: :ignore, updated_since: :ignore, contract_period_id: :ignore)
      @contract_period_id = contract_period_id
      @scope = eligible_schools.not_cip_only.select(
        "schools.*",
        transient_in_partnership,
        transient_training_programme(lead_provider.id),
        transient_expression_of_interest(lead_provider.id)
      ).or(schools_with_existing_partnerships)
            .or(schools_with_expression_of_interests(lead_provider.id))
            .distinct

      where_urn_is(urn)
      where_updated_since(updated_since)
    end

    def schools
      return School.none if ignore?(filter: contract_period_id)

      scope.order("schools.created_at ASC")
    end

    def school_by_api_id(api_id)
      return scope.find_by!(api_id:) if api_id.present?

      fail(ArgumentError, "api_id needed")
    end

    def school(id)
      return scope.find(id) if id.present?

      fail(ArgumentError, "id needed")
    end

  private

    def eligible_schools
      School.eligible
    end

    def schools_with_existing_partnerships
      School.where(id: School.select("schools.id")
        .joins(school_partnerships: { lead_provider_delivery_partnership: { active_lead_provider: :contract_period } })
        .where(contract_periods: { year: contract_period_id }))
    end

    def schools_with_expression_of_interests(lead_provider_id)
      schools_with_ects_expressions_of_interest = School.select("schools.id")
        .joins(ect_at_school_periods: { training_periods: { expression_of_interest: %i[contract_period lead_provider] } })
        .where.not(training_periods: { expression_of_interest_id: nil })
        .where(contract_periods: { year: contract_period_id })
        .where(lead_provider: { id: lead_provider_id })
        .group("schools.id")

      schools_with_mentors_expressions_of_interest = School.select("schools.id")
        .joins(mentor_at_school_periods: { training_periods: { expression_of_interest: %i[contract_period lead_provider] } })
        .where.not(training_periods: { expression_of_interest_id: nil })
        .where(contract_periods: { year: contract_period_id })
        .where(lead_provider: { id: lead_provider_id })
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

    def transient_in_partnership
      "EXISTS(
          SELECT 1 AS one
          FROM schools AS s
          INNER JOIN school_partnerships AS sp ON s.id = sp.school_id
          INNER JOIN lead_provider_delivery_partnerships AS lpd ON sp.lead_provider_delivery_partnership_id = lpd.id
          INNER JOIN active_lead_providers AS alp ON lpd.active_lead_provider_id = alp.id
          INNER JOIN contract_periods AS rp ON alp.contract_period_id = rp.year
            WHERE schools.id = s.id
            AND rp.year = #{contract_period_id}
            LIMIT 1
        ) AS transient_in_partnership"
    end

    def transient_training_programme(lead_provider_id)
      "CASE
            WHEN NOT EXISTS (
              SELECT 1 AS one
              FROM schools AS s
              INNER JOIN school_partnerships AS sp ON s.id = sp.school_id
              INNER JOIN lead_provider_delivery_partnerships AS lpd ON sp.lead_provider_delivery_partnership_id = lpd.id
              INNER JOIN active_lead_providers AS alp ON lpd.active_lead_provider_id = alp.id
              INNER JOIN contract_periods AS rp ON alp.contract_period_id = rp.year
                WHERE schools.id = s.id
                AND rp.year = #{contract_period_id}
                LIMIT 1
            )
            THEN 'not_yet_known'

            WHEN EXISTS (
               SELECT 1 AS one
                 FROM schools AS s
                 INNER JOIN mentor_at_school_periods AS masp ON s.id = masp.school_id
                 INNER JOIN training_periods AS tp ON masp.id = tp.mentor_at_school_period_id
                 INNER JOIN school_partnerships AS sp ON tp.school_partnership_id = sp.id
                 INNER JOIN lead_provider_delivery_partnerships AS lpd ON sp.lead_provider_delivery_partnership_id = lpd.id
                 INNER JOIN active_lead_providers AS alp ON lpd.active_lead_provider_id = alp.id
                 INNER JOIN contract_periods AS rp ON alp.contract_period_id = rp.year
                 WHERE schools.id = s.id
                 AND rp.year = #{contract_period_id}
                 AND alp.lead_provider_id = #{lead_provider_id}
                 LIMIT 1
            )
            THEN 'provider_led'

            WHEN EXISTS (
               SELECT 1 AS one
                 FROM schools AS s
                 INNER JOIN ect_at_school_periods AS easp ON s.id = easp.school_id
                 INNER JOIN training_periods AS tp ON easp.id = tp.ect_at_school_period_id
                 INNER JOIN school_partnerships AS sp ON tp.school_partnership_id = sp.id
                 INNER JOIN lead_provider_delivery_partnerships AS lpd ON sp.lead_provider_delivery_partnership_id = lpd.id
                 INNER JOIN active_lead_providers AS alp ON lpd.active_lead_provider_id = alp.id
                 INNER JOIN contract_periods AS rp ON alp.contract_period_id = rp.year
                 WHERE schools.id = s.id
                 AND rp.year = #{contract_period_id}
                 AND alp.lead_provider_id = #{lead_provider_id}
                 LIMIT 1
            )
            THEN (
              CASE
                WHEN (
                  SELECT DISTINCT(easp.training_programme) AS training_programme
                  FROM schools AS s
                  INNER JOIN ect_at_school_periods AS easp ON s.id = easp.school_id
                  INNER JOIN training_periods AS tp ON easp.id = tp.ect_at_school_period_id
                  INNER JOIN school_partnerships AS sp ON tp.school_partnership_id = sp.id
                  INNER JOIN lead_provider_delivery_partnerships AS lpd ON sp.lead_provider_delivery_partnership_id = lpd.id
                  INNER JOIN active_lead_providers AS alp ON lpd.active_lead_provider_id = alp.id
                  INNER JOIN contract_periods AS rp ON alp.contract_period_id = rp.year
                  WHERE schools.id = s.id
                  AND rp.year = #{contract_period_id}
                  AND alp.lead_provider_id = #{lead_provider_id}
                  ORDER BY easp.training_programme ASC
                  LIMIT 1
                ) = 'provider_led'
                THEN 'provider_led'

                WHEN (
                  SELECT DISTINCT(easp.training_programme) AS training_programme
                  FROM schools AS s
                  INNER JOIN ect_at_school_periods AS easp ON s.id = easp.school_id
                  INNER JOIN training_periods AS tp ON easp.id = tp.ect_at_school_period_id
                  INNER JOIN school_partnerships AS sp ON tp.school_partnership_id = sp.id
                  INNER JOIN lead_provider_delivery_partnerships AS lpd ON sp.lead_provider_delivery_partnership_id = lpd.id
                  INNER JOIN active_lead_providers AS alp ON lpd.active_lead_provider_id = alp.id
                  INNER JOIN contract_periods AS rp ON alp.contract_period_id = rp.year
                  WHERE schools.id = s.id
                  AND rp.year = #{contract_period_id}
                  AND alp.lead_provider_id = #{lead_provider_id}
                  ORDER BY easp.training_programme ASC
                  LIMIT 1
                ) = 'school_led'
                THEN 'school_led'
              END
            )
            ELSE 'not_yet_known'
        END AS transient_training_programme"
    end

    def transient_expression_of_interest(lead_provider_id)
      "CASE
            WHEN EXISTS (
               SELECT 1 AS one
                 FROM schools AS s
                 INNER JOIN mentor_at_school_periods AS masp ON s.id = masp.school_id
                 INNER JOIN training_periods AS tp ON masp.id = tp.mentor_at_school_period_id
                 INNER JOIN active_lead_providers AS alp ON tp.expression_of_interest_id = alp.id
                 INNER JOIN contract_periods AS rp ON alp.contract_period_id = rp.year
                 WHERE schools.id = s.id
                 AND rp.year = #{contract_period_id}
                 AND alp.lead_provider_id = #{lead_provider_id}
                 LIMIT 1
            )
            THEN true

            WHEN EXISTS (
               SELECT 1 AS one
                 FROM schools AS s
                 INNER JOIN ect_at_school_periods AS easp ON s.id = easp.school_id
                 INNER JOIN training_periods AS tp ON easp.id = tp.ect_at_school_period_id
                 INNER JOIN active_lead_providers AS alp ON tp.expression_of_interest_id = alp.id
                 INNER JOIN contract_periods AS rp ON alp.contract_period_id = rp.year
                 WHERE schools.id = s.id
                 AND rp.year = #{contract_period_id}
                 AND alp.lead_provider_id = #{lead_provider_id}
                 LIMIT 1
            )
            THEN true
            ELSE false
        END AS transient_expression_of_interest"
    end
  end
end
