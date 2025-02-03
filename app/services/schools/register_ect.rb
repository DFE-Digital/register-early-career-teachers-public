module Schools
  class RegisterECT
    attr_reader :corrected_name, :trs_first_name, :trs_last_name, :started_on, :school, :teacher, :trn, :working_pattern

    def initialize(trs_first_name:, trs_last_name:, trn:, school:, corrected_name:, started_on:, working_pattern:)
      @trs_first_name = trs_first_name
      @trs_last_name = trs_last_name
      @started_on = started_on
      @corrected_name = corrected_name
      @trn = trn
      @school = school
      @working_pattern = working_pattern
    end

    def register!
      ActiveRecord::Base.transaction do
        create_teacher!
        start_at_school!
      end
    end

  private

    def already_registered_as_an_ect?
      ::Teacher.find_by_trn(trn)&.ect_at_school_periods&.exists?
    end

    def create_teacher!
      raise ActiveRecord::RecordInvalid if already_registered_as_an_ect?

      @teacher = ::Teacher.create_with(trs_first_name:, trs_last_name:, corrected_name:)
                          .find_or_create_by!(trn:)
    end

    def start_at_school!
      teacher.ect_at_school_periods.create!(school:, started_on:, working_pattern:)
    end
  end
end
