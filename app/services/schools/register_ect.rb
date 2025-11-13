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
      ActiveRecord::Base.transaction do
        create_teacher!
        not_registered_as_an_ect!
        update_school_last_choices!
        close_ongoing_ect_period!
        @ect_at_school_period = start_at_school!
        create_training_period!
        set_eligibility_for_funding!
        record_event!
      end

      @ect_at_school_period
    end

  private

    def already_registered_as_an_ect?
      # Check if ECT is already registered at THIS school to prevent duplicates
      # School transfers to different schools are allowed
      teacher.ect_at_school_periods.where(school:).ongoing_today.exists?
    end

    def not_registered_as_an_ect!
      raise ActiveRecord::RecordInvalid if already_registered_as_an_ect?
    end

    def create_teacher!
      @teacher = ::Teacher.create_with(
        trs_first_name:,
        trs_last_name:,
        corrected_name:,
        api_ect_training_record_id: SecureRandom.uuid
      ).find_or_create_by!(trn:)
    end

    def create_training_period!
      @training_period = case training_programme
                         when 'school_led'
                           ::TrainingPeriods::Create.school_led(
                             period: ect_at_school_period,
                             started_on: ect_at_school_period.started_on
                           ).call
                         when 'provider_led'
                           ::TrainingPeriods::Create.provider_led(
                             period: ect_at_school_period,
                             started_on: ect_at_school_period.started_on,
                             school_partnership:,
                             expression_of_interest:,
                             author:
                           ).call
                         end
    end

    def school_partnership
      earliest_matching_school_partnership
    end

    def start_at_school!
      teacher.ect_at_school_periods.build(school_reported_appropriate_body:,
                                          email:,
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

    def close_ongoing_ect_period!
      return unless teacher

      ongoing_period = teacher.ect_at_school_periods.ongoing.started_on_or_before(started_on).first
      return unless ongoing_period

      ECTAtSchoolPeriods::Finish.new(
        ect_at_school_period: ongoing_period,
        finished_on: started_on,
        author:
      ).finish!
    end

    def set_eligibility_for_funding!
      Teachers::SetFundingEligibility.new(
        teacher:,
        author:
      ).set!
    end

    def record_event!
      Events::Record.record_teacher_registered_as_ect_event!(author:, ect_at_school_period:, teacher:, school:, training_period:)
    end
  end
end
