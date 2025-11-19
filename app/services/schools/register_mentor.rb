module Schools
  class RegisterMentor
    class MentorIneligibleForTraining < StandardError; end
    include TrainingPeriodSources

    attr_reader :author,
                :trs_first_name,
                :trs_last_name,
                :corrected_name,
                :school_urn,
                :teacher,
                :trn,
                :email,
                :started_on,
                :mentor_at_school_period,
                :lead_provider,
                :training_period,
                :finish_existing_at_school_periods

    def initialize(trs_first_name:,
                   trs_last_name:,
                   corrected_name:,
                   trn:,
                   school_urn:,
                   email:,
                   author:,
                   finish_existing_at_school_periods: false,
                   started_on: nil,
                   lead_provider: nil)
      @author = author
      @trs_first_name = trs_first_name
      @trs_last_name = trs_last_name
      @corrected_name = corrected_name
      @school_urn = school_urn
      @email = email
      @started_on = started_on&.to_date || Date.current
      @trn = trn
      @lead_provider = lead_provider
      @finish_existing_at_school_periods = finish_existing_at_school_periods
    end

    def register!
      ActiveRecord::Base.transaction do
        create_teacher!
        finish_existing_at_school_periods! if finish_existing_at_school_periods
        start_at_school!
        create_training_period!
        set_eligibility_for_funding!
        record_event!
      end

      mentor_at_school_period
    end

  private

    def training_programme
      (lead_provider.present?) ? 'provider_led' : 'school_led'
    end

    def create_training_period!
      return if training_programme == 'school_led'

      ensure_mentor_is_eligible!

      @training_period = ::TrainingPeriods::Create.provider_led(period: mentor_at_school_period,
                                                                started_on: mentor_at_school_period.started_on,
                                                                school_partnership:,
                                                                expression_of_interest:,
                                                                author: @author).call
    end

    def ensure_mentor_is_eligible!
      if Teachers::MentorFundingEligibility.new(trn: teacher.trn).ineligible?
        raise MentorIneligibleForTraining,
              "Mentor #{teacher.id} is not eligible for funded training"
      end
    end

    def school_partnership
      earliest_matching_school_partnership if lead_provider.present?
    end

    def create_teacher!
      @teacher = ::Teacher.create_with(
        trs_first_name:,
        trs_last_name:,
        corrected_name:,
        api_mentor_training_record_id: SecureRandom.uuid
      ).find_or_create_by!(trn:)
    end

    def school
      @school ||= School.find_by(urn: school_urn)
    end

    def finish_existing_at_school_periods!
      MentorAtSchoolPeriods::Finish.new(teacher:, finished_on: started_on, author:).finish_existing_at_school_periods!
    end

    def start_at_school!
      @mentor_at_school_period = teacher.mentor_at_school_periods.create!(school:, started_on:, email:)
    end

    def set_eligibility_for_funding!
      Teachers::SetFundingEligibility.new(
        teacher:,
        author:
      ).set!
    end

    def record_event!
      Events::Record.record_teacher_registered_as_mentor_event!(author:, mentor_at_school_period:, teacher:, school:, training_period:, lead_provider:)
    end
  end
end
