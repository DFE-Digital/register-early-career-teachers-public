module Admin
  class TeacherPresenter < SimpleDelegator
    def self.wrap(collection)
      collection.map { |teacher| new(teacher) }
    end

    def full_name
      ::Teachers::Name.new(teacher).full_name
    end

    def roles
      ::Teachers::Role.new(teacher:).to_s
    end

    def ect?
      teacher.ect_at_school_periods.any?
    end

    def mentor?
      teacher.mentor_at_school_periods.any?
    end

    def latest_school_period_as_an_ect
      latest = school_periods_as_an_ect.first
      SchoolPeriodPresenter.new(latest) if latest.present?
    end

    def school_periods_as_an_ect
      teacher.ect_at_school_periods.order(started_on: :desc)
    end

    def latest_school_period_as_a_mentor
      latest = school_periods_as_a_mentor.first
      SchoolPeriodPresenter.new(latest) if latest.present?
    end

    def school_periods_as_a_mentor
      teacher.mentor_at_school_periods.order(started_on: :desc)
    end

    def has_migration_failures?
      MigrationFailure.where(parent_id: teacher.id, parent_type: "Teacher").any? ||
        teacher.teacher_migration_failures.any?
    end

    def most_recent_email
      period = [latest_ect_period, latest_mentor_period].compact.max_by(&:started_on)
      period&.email || 'No email recorded'
    end

    def current_schools
      @current_schools ||= begin
        ect_schools = teacher.ect_at_school_periods.ongoing.includes(school: :gias_school).map(&:school)
        mentor_schools = teacher.mentor_at_school_periods.ongoing.includes(school: :gias_school).map(&:school)
        (ect_schools + mentor_schools).compact.uniq(&:id)
      end
    end

    def induction_status
      return unless ect?

      ::Teachers::InductionStatus.new(trs_induction_status: teacher.trs_induction_status, teacher:).induction_status
    end

    def api_participant_id
      teacher.api_id.presence || 'Not available'
    end

  private

    def teacher
      __getobj__
    end

    def latest_ect_period
      teacher.ect_at_school_periods.latest_first.first
    end

    def latest_mentor_period
      teacher.mentor_at_school_periods.latest_first.first
    end
  end
end
