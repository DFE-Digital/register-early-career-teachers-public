module Schools
  class TrainingProgramme
    def initialize(school:, registration_period_id:)
      @school = school
      @registration_period_id = registration_period_id.to_i
    end

    def training_programme
      return not_yet_known unless partnership_exists?
      return provider_led if mentors_at_school?

      ect_training_programme || not_yet_known
    end

  private

    attr_reader :school, :registration_period_id

    def ect_at_school_periods
      @ect_at_school_periods ||= school.ect_at_school_periods.for_registration_period(registration_period_id)
    end

    def mentors_at_school_periods
      @mentors_at_school_periods ||= school.mentor_at_school_periods.for_registration_period(registration_period_id)
    end

    def partnership_exists?
      school.school_partnerships.for_registration_period(registration_period_id).exists?
    end

    def mentors_at_school?
      mentors_at_school_periods.exists?
    end

    def ect_training_programme
      ect_at_school_periods.order(training_programme: :asc).pick(:training_programme)
    end

    def not_yet_known
      "not_yet_known"
    end

    def provider_led
      "provider_led"
    end
  end
end
