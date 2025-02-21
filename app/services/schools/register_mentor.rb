module Schools
  class RegisterMentor
    attr_reader :author, :trs_first_name, :trs_last_name, :corrected_name, :school_urn, :email, :started_on, :teacher, :trn

    def initialize(trs_first_name:, trs_last_name:, corrected_name:, trn:, school_urn:, email:, started_on: Date.current, author: nil)
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
    end

  private

    def already_registered_as_a_mentor?
      ::Teacher.find_by_trn(trn)&.mentor_at_school_periods&.exists?
    end

    def create_teacher!
      raise ActiveRecord::RecordInvalid if already_registered_as_a_mentor?

      # FIXME: UX needs graceful redirect at this point

      @teacher = ::Teacher.create_with(trs_first_name:, trs_last_name:, corrected_name:)
                          .find_or_create_by!(trn:)
    end

    def record_event!
      Events::Record.new(
        author: author,
        event_type: :teacher_registered_at_school,
        heading: "Mentor #{teacher_name} registered at #{school.name} starting on #{started_on}",
        teacher:,
        mentor_at_school_period:,
        school:,
        happened_at: Time.zone.now
      ).record_event!
    end

    def school
      @school ||= School.find_by(urn: school_urn)
    end

    def start_at_school!
      teacher.mentor_at_school_periods.create!(school:, started_on:, email:)
    end

    def teacher_name
      @teacher_name ||= Teachers::Name.new(teacher).full_name
    end
  end
end
