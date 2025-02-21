module Schools
  class RegisterECT
    attr_reader :corrected_name, :trs_first_name, :trs_last_name, :email, :started_on,
                :school, :teacher, :trn, :working_pattern,
                :appropriate_body, :lead_provider, :programme_type

    def initialize(trs_first_name:, trs_last_name:, email:, trn:, school:,
                   corrected_name:, started_on:, working_pattern:,
                   appropriate_body:, programme_type:, lead_provider:)
      @trs_first_name = trs_first_name
      @trs_last_name = trs_last_name
      @started_on = started_on
      @corrected_name = corrected_name
      @trn = trn
      @school = school
      @working_pattern = working_pattern
      @email = email
      @appropriate_body = appropriate_body
      @programme_type = programme_type
      @lead_provider = lead_provider
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
      teacher.ect_at_school_periods.create!(school:, started_on:, working_pattern:, email:,
                                            appropriate_body:, lead_provider:, programme_type:)
    end
  end
end
