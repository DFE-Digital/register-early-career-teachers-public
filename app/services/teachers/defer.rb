module Teachers
  class Defer
    attr_reader :teacher, :lead_provider, :course_identifier, :deferral_reason

    def initialize(teacher:, lead_provider:, course_identifier:, deferral_reason:)
      @teacher = teacher
      @lead_provider = lead_provider
      @course_identifier = course_identifier
      @deferral_reason = deferral_reason
    end

    def defer!
      finish_training_period! if training_period.ongoing?
      mark_training_period_as_deferred!
    end

  private

    def finish_training_period!
      options = {
        training_period:,
        finished_on:,
        teacher:,
        author: Events::LeadProviderAPIAuthor.new(lead_provider:),
      }

      service = if mentor_course_identifier?
                  TrainingPeriods::Finish.mentor_training(**options.merge(ect_at_school_period:))
                else
                  TrainingPeriods::Finish.ect_training(**options.merge(mentor_at_school_period:))
                end

      service.finish!
    end

    def mark_training_period_as_deferred!
      training_period.update!(api_deferred_at: finished_on, deferral_reason:)
    end

    def finished_on
      @finished_on ||= Time.zone.now.to_date
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

    def mentor_course_identifier?
      course_identifier == "ecf-mentor"
    end

    def metadata
      @metadata ||= teacher
        .lead_provider_metadata
        .find_by(lead_provider:)
    end
  end
end
