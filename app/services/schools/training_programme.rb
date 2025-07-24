module Schools
  class TrainingProgramme
    def initialize(school:, contract_period_id:)
      @school = school
      @contract_period_id = contract_period_id.to_i
    end

    def training_programme
      return provider_led if mentors_at_school?

      ect_training_programme || not_yet_known
    end

  private

    attr_reader :school, :contract_period_id

    def ects_expressions_of_interest
      @ects_expressions_of_interest ||= school.ect_at_school_periods.with_expressions_of_interest_for_contract_period(contract_period_id)
    end

    def mentors_expressions_of_interest
      @mentors_expressions_of_interest ||= school.mentor_at_school_periods.with_expressions_of_interest_for_contract_period(contract_period_id)
    end

    def ect_at_school_periods
      @ect_at_school_periods ||= school.ect_at_school_periods.with_partnerships_for_contract_period(contract_period_id)
    end

    def mentors_at_school_periods
      @mentors_at_school_periods ||= school.mentor_at_school_periods.with_partnerships_for_contract_period(contract_period_id)
    end

    def mentors_at_school?
      return school.transient_mentors_at_school if school.respond_to?(:transient_mentors_at_school)

      mentors_expressions_of_interest.exists? || mentors_at_school_periods.exists?
    end

    def ect_training_programme
      return school.transient_ects_at_school_training_programme if school.respond_to?(:transient_ects_at_school_training_programme)

      TrainingPeriod
        .where(ect_at_school_period_id: ects_expressions_of_interest.pluck(:id) + ect_at_school_periods.pluck(:id))
        .order(training_programme: :asc)
        .pick(:training_programme)
    end

    def not_yet_known
      "not_yet_known"
    end

    def provider_led
      "provider_led"
    end
  end
end
