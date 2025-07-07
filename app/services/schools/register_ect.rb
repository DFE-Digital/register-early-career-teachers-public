module Schools
  class RegisterECT
    include TrainingPeriodSources
    attr_reader :school_reported_appropriate_body,
                :corrected_name,
                :email,
                :lead_provider,
                :training_programme,
                :school,
                :started_on,
                :teacher,
                :trn,
                :trs_first_name,
                :trs_last_name,
                :working_pattern,
                :author,
                :ect_at_school_period,
                :training_period

    def initialize(school_reported_appropriate_body:,
                   corrected_name:,
                   email:,
                   lead_provider:,
                   training_programme:,
                   school:,
                   started_on:,
                   trn:,
                   trs_first_name:,
                   trs_last_name:,
                   working_pattern:,
                   author:)
      @school_reported_appropriate_body = school_reported_appropriate_body
      @corrected_name = corrected_name
      @email = email
      @lead_provider = lead_provider
      @training_programme = training_programme
      @school = school
      @started_on = started_on
      @trn = trn
      @trs_first_name = trs_first_name
      @trs_last_name = trs_last_name
      @working_pattern = working_pattern
      @author = author
    end

    def register!
      not_registered_as_an_ect!

      ActiveRecord::Base.transaction do
        update_school_last_choices!
        create_teacher!
        @ect_at_school_period = start_at_school!
        create_training_period! if provider_led_training_programme?
        record_event!
      end

      @ect_at_school_period
    end

  private

    def provider_led_training_programme?
      @training_programme == 'provider_led'
    end

    def already_registered_as_an_ect?
      ::Teacher.find_by_trn(trn)&.ect_at_school_periods&.exists?
    end

    def not_registered_as_an_ect!
      raise ActiveRecord::RecordInvalid if already_registered_as_an_ect?
    end

    def create_teacher!
      @teacher = ::Teacher.create_with(trs_first_name:, trs_last_name:, corrected_name:).find_or_create_by!(trn:)
    end

    def create_training_period!
      @training_period = ::TrainingPeriods::Create.new(
        period: ect_at_school_period,
        started_on: ect_at_school_period.started_on,
        school_partnership: earliest_matching_school_partnership,
        expression_of_interest:
      ).call
    end

    def start_at_school!
      teacher.ect_at_school_periods.build(school_reported_appropriate_body:,
                                          email:,
                                          training_programme:,
                                          school:,
                                          started_on:,
                                          working_pattern:) do |ect|
        ect.save!(context: :register_ect)
      end
    end

    def update_school_last_choices!
      school.update!(last_chosen_appropriate_body: school_reported_appropriate_body,
                     last_chosen_lead_provider: lead_provider,
                     last_chosen_training_programme: training_programme)
    end

    def record_event!
      Events::Record.record_teacher_registered_as_ect_event!(author:, ect_at_school_period:, teacher:, school:, training_period:)
    end
  end
end
