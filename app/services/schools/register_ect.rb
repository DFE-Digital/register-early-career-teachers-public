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

    def register_teacher!
      ActiveRecord::Base.transaction do
        create_teacher!
        start_at_school!
      end
    end

  private

    def create_teacher!
      @teacher = ::Teacher.where(trn:)
                          .first_or_create!(trs_first_name:, trs_last_name:, trn:, corrected_name:)
    end

    def start_at_school!
      teacher.ect_at_school_periods.create!(school:, started_on:, working_pattern:)
    end
  end
end
