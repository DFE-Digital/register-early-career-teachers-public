module Schools
  class TrainingProgramme
    def initialize(school:)
      @school = school
    end

    def training_programme_for(contract_period_year:)
      return provider_led if mentors_at_school?(contract_period_year:)

      ect_training_programme(contract_period_year:) || not_yet_known
    end

  private

    attr_reader :school, :contract_period_year

    def ect_expressions_of_interest_ids_by_contract_period_year
      @ect_expressions_of_interest_ids_by_contract_period_year ||= school
        .ect_at_school_periods
        .joins(training_periods: { expression_of_interest: :contract_period })
        .pluck(:contract_period_year, :id)
        .group_by(&:first)
        .transform_values { |pairs| pairs.map(&:last) }
    end

    def mentors_expressions_of_interest_contract_period_years
      @mentors_expressions_of_interest_contract_period_years ||= school.mentor_at_school_periods.joins(training_periods: {
        expression_of_interest: :contract_period
      }).pluck(:contract_period_year)
    end

    def ect_at_school_period_ids_by_contract_period_year
      @ect_at_school_period_ids_by_contract_period_year ||= school
        .ect_at_school_periods
        .joins(training_periods: { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } })
        .pluck(:contract_period_year, :id)
        .group_by(&:first)
        .transform_values { |pairs| pairs.map(&:last) }
    end

    def mentors_at_school_periods_contract_period_years
      @mentors_at_school_periods_contract_period_years ||= school
        .mentor_at_school_periods
        .joins(training_periods: { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } })
        .pluck(:contract_period_year)
    end

    def mentors_at_school?(contract_period_year:)
      contract_period_year.in?(mentors_expressions_of_interest_contract_period_years) || contract_period_year.in?(mentors_at_school_periods_contract_period_years)
    end

    def ect_training_programme(contract_period_year:)
      ect_at_school_period_id = ((ect_expressions_of_interest_ids_by_contract_period_year[contract_period_year] || []) +
        (ect_at_school_period_ids_by_contract_period_year[contract_period_year] || []) +
        school_led_ect_at_school_period_ids).compact

      TrainingPeriod
        .where(ect_at_school_period_id:)
        .order(training_programme: :asc)
        .pick(:training_programme)
    end

    def not_yet_known
      "not_yet_known"
    end

    def provider_led
      "provider_led"
    end

    def school_led_ect_at_school_period_ids
      @school_led_ect_at_school_period_ids ||= school.ect_at_school_periods.joins(:training_periods)
        .where(training_periods: { training_programme: 'school_led' })
        .where(training_periods: { expression_of_interest_id: nil, school_partnership_id: nil })
        .distinct
        .pluck(:id)
    end

    def school_led_ect_at_school_periods
      @school_led_ect_at_school_periods ||= school.ect_at_school_periods.joins(:training_periods)
        .where(training_periods: { training_programme: 'school_led' })
        .where(training_periods: { expression_of_interest_id: nil, school_partnership_id: nil })
        .distinct
    end
  end
end
