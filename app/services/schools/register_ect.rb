module Schools
  class RegisterECT
    attr_reader :appropriate_body,
                :appropriate_body_type,
                :corrected_name,
                :email,
                :lead_provider,
                :programme_type,
                :school,
                :started_on,
                :teacher,
                :trn,
                :trs_first_name,
                :trs_last_name,
                :working_pattern

    def initialize(appropriate_body:,
                   appropriate_body_type:,
                   corrected_name:,
                   email:,
                   lead_provider:,
                   programme_type:,
                   school:,
                   started_on:,
                   trn:,
                   trs_first_name:,
                   trs_last_name:,
                   working_pattern:)
      @appropriate_body = appropriate_body
      @appropriate_body_type = appropriate_body_type
      @corrected_name = corrected_name
      @email = email
      @lead_provider = lead_provider
      @programme_type = programme_type
      @school = school
      @started_on = started_on
      @trn = trn
      @trs_first_name = trs_first_name
      @trs_last_name = trs_last_name
      @working_pattern = working_pattern
    end

    def register!
      ActiveRecord::Base.transaction do
        create_teacher!
        start_at_school!
        update_school_choices!
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
      teacher.ect_at_school_periods.create!(school:,
                                            started_on:,
                                            working_pattern:,
                                            email:,
                                            appropriate_body:,
                                            appropriate_body_type:,
                                            lead_provider:,
                                            programme_type:)
    end

    def update_school_choices!
      school.update!(chosen_appropriate_body: appropriate_body,
                     chosen_appropriate_body_type: appropriate_body_type,
                     chosen_lead_provider: lead_provider,
                     chosen_programme_type: programme_type)
    end
  end
end
