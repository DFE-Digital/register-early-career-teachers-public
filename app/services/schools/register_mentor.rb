module Schools
  class RegisterMentor
    attr_reader :trs_first_name, :trs_last_name, :corrected_name, :school_urn, :started_on, :teacher, :trn

    def initialize(trs_first_name:, trs_last_name:, corrected_name:, trn:, school_urn:, started_on: Date.current)
      @trs_first_name = trs_first_name
      @trs_last_name = trs_last_name
      @corrected_name = corrected_name
      @school_urn = school_urn
      @started_on = started_on
      @trn = trn
    end

    def register!
      ActiveRecord::Base.transaction do
        create_teacher!
        start_at_school!
      end
    end

  private

    def already_registered_as_a_mentor?
      ::Teacher.find_by_trn(trn)&.mentor_at_school_periods&.exists?
    end

    def create_teacher!
      raise ActiveRecord::RecordInvalid if already_registered_as_a_mentor?

      @teacher = ::Teacher.create_with(trs_first_name:, trs_last_name:, corrected_name:)
                          .find_or_create_by!(trn:)
    end

    def school
      @school ||= School.find_by(urn: school_urn)
    end

    def start_at_school!
      teacher.mentor_at_school_periods.create!(school:, started_on:)
    end
  end
end
