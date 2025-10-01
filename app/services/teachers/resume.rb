module Teachers
  class Resume
    attr_reader :teacher, :lead_provider, :course_identifier

    def initialize(teacher:, lead_provider:, course_identifier:)
      @teacher = teacher
      @lead_provider = lead_provider
      @course_identifier = course_identifier
    end

    def resume!
      create_training_period!
    end

  private

    def create_training_period!
      ::TrainingPeriods::Create.provider_led(
        period:,
        started_on: Time.zone.now.to_date,
        school_partnership: training_period.school_partnership
      ).call
    end

    def started_on
      @started_on ||= Time.zone.now.to_date
    end

    def ect_at_school_period
      @ect_at_school_period ||= training_period.ect_at_school_period
    end

    def mentor_at_school_period
      @mentor_at_school_period ||= training_period.mentor_at_school_period
    end

    def training_period
      @training_period ||= if mentor_course_identifier?
                             metadata.latest_mentor_training_period
                           else
                             metadata.latest_ect_training_period
                           end
    end

    def period
      @period ||= if mentor_course_identifier?
                    mentor_at_school_period
                  else
                    ect_at_school_period
                  end
    end

    def mentor_course_identifier?
      course_identifier == "ecf-mentor"
    end
  end
end
