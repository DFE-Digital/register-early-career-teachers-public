module Admin
  class SchoolPeriodPresenter < SimpleDelegator
    def self.wrap(collection)
      collection.map { |item| new(item) }
    end

    def school_name_and_urn
      "#{school_period.school.gias_school.name} (#{school_period.school.urn})"
    end

    def formatted_started_on
      school_period.started_on.to_fs(:govuk)
    end

    def formatted_finished_on
      return "" if school_period.finished_on.blank?

      school_period.finished_on.to_fs(:govuk)
    end

    def latest_mentorship_period
      mentorship_periods.first
    end

    def mentees
      school_period.mentorship_periods.ongoing.map { |mp| mp.mentee.teacher }.sort(&:trs_last_name)
    end

    def mentorship_periods
      MentorshipPeriodPresenter.wrap(school_period.mentorship_periods.order(started_on: :desc))
    end

    def latest_training_period
      training_periods.first
    end

    def training_periods
      TrainingPeriodPresenter.wrap(school_period.training_periods.order(started_on: :desc))
    end

  private

    def school_period
      __getobj__
    end
  end
end
