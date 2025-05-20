module Schools
  class RegisterMentor
    attr_reader :author,
                :trs_first_name,
                :trs_last_name,
                :corrected_name,
                :school_urn,
                :teacher,
                :trn,
                :email,
                :started_on,
                :mentor_at_school_period

    def initialize(trs_first_name:,
                   trs_last_name:,
                   corrected_name:,
                   trn:,
                   school_urn:,
                   email:,
                   author:,
                   started_on: Date.current)
      @author = author
      @trs_first_name = trs_first_name
      @trs_last_name = trs_last_name
      @corrected_name = corrected_name
      @school_urn = school_urn
      @email = email
      @started_on = started_on
      @trn = trn
    end

    def register!
      ActiveRecord::Base.transaction do
        create_teacher!
        start_at_school!
        record_event!
      end

      mentor_at_school_period
    end

  private

    def already_registered_as_a_mentor?
      ::Teacher.find_by_trn(trn)&.mentor_at_school_periods&.exists?
    end

    # FIXME: UX needs graceful redirect at this point
    def create_teacher!
      raise ActiveRecord::RecordInvalid if already_registered_as_a_mentor?

      @teacher = ::Teacher.create_with(
        trs_first_name:,
        trs_last_name:,
        corrected_name:
      ).find_or_create_by!(trn:)
    end

    def school
      @school ||= School.find_by(urn: school_urn)
    end

    def start_at_school!
      @mentor_at_school_period = teacher.mentor_at_school_periods.create!(school:, started_on:, email:)
    end

    def record_event!
      Events::Record.record_teacher_registered_as_mentor_event!(author:, mentor_at_school_period:, teacher:, school:)
    end
  end
end
