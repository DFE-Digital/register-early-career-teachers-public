module Schools
  class RegisterECT
    attr_reader :corrected_name, :first_name, :last_name, :started_on, :school, :teacher, :trn

    def initialize(first_name:, last_name:, trn:, corrected_name:, school:, started_on:)
      @first_name = first_name
      @last_name = last_name
      @started_on = started_on
      @corrected_name = corrected_name
      @trn = trn
      @school = school
    end

    def register_teacher!
      ActiveRecord::Base.transaction do
        create_teacher!
        start_at_school!
      end
    end

  private

    def create_teacher!
      @teacher = ::Teacher.create!(first_name:, last_name:, trn:, corrected_name:)
    end

    def start_at_school!
      teacher.ect_at_school_periods.create!(school:, started_on:)
    end
  end
end
