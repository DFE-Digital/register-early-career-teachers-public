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
                :mentoring_at_new_school_only,
                :mentee

    def initialize(trs_first_name:,
                   trs_last_name:,
                   corrected_name:,
                   trn:,
                   school_urn:,
                   email:,
                   author:,
                   mentoring_at_new_school_only: false,
                   started_on: nil,
                   lead_provider: nil,
                   mentee: nil)
      @author = author
      @trs_first_name = trs_first_name
      @trs_last_name = trs_last_name
      @corrected_name = corrected_name
      @school_urn = school_urn
      @email = email
      @started_on = started_on&.to_date || Date.current
      @trn = trn
      @lead_provider = lead_provider
      @mentoring_at_new_school_only = mentoring_at_new_school_only
      @mentee = mentee
    end

    def register!
      ActiveRecord::Base.transaction do
        create_teacher!
        finish_periods_at_all_schools! if mentoring_at_new_school_only?
        start_at_school!
        create_training_period! unless mentoring_at_several_schools?
        set_eligibility_for_funding!
        record_event!
      end

      send_confirmation_email!

      mentor_at_school_period
    end

  private

    def training_programme
      (lead_provider.present?) ? "provider_led" : "school_led"
    end

    def create_training_period!
      return if training_programme == "school_led"
      return if mentor_ineligible_for_funding?

      @training_period = ::TrainingPeriods::Create.provider_led(period: mentor_at_school_period,
                                                                started_on: mentor_at_school_period.started_on,
                                                                school_partnership:,
                                                                expression_of_interest:,
                                                                mentee:,
                                                                author: @author,
                                                                contract_period: resolved_contract_period).call
    end

    def mentor_ineligible_for_funding?
      Teachers::MentorFundingEligibility.new(trn: teacher.trn).ineligible?
    end

    def school_partnership
      earliest_matching_school_partnership if lead_provider.present?
    end

    def contract_period
      resolved_contract_period
    end

    def resolved_contract_period
      @resolved_contract_period ||= ContractPeriods::ForMentorRegistration.new(
        started_on: mentor_at_school_period.started_on,
        previous_training_period:
      ).call
    end

    def previous_training_period
      @previous_training_period ||= TrainingPeriod
                                      .for_mentor_trn(teacher.trn)
                                      .order(started_on: :desc)
                                      .first
    end

    def create_teacher!
      @teacher = ::Teacher.create_with(
        trs_first_name:,
        trs_last_name:,
        corrected_name:
      ).find_or_create_by!(trn:)
    end

    def school
      @school ||= School.find_by(urn: school_urn)
    end

    def finish_periods_at_all_schools!
      MentorAtSchoolPeriods::Finish.new(teacher:, finished_on: started_on, author:).finish_periods_at_all_schools!
    end

    def mentoring_at_several_schools?
      return false if mentoring_at_new_school_only?

      teacher
        .mentor_at_school_periods
        .current_or_future
        .where.not(school:)
        .exists?
    end

    def start_at_school!
      @mentor_at_school_period = teacher.mentor_at_school_periods.create!(school:, started_on:, email:)
    end

    def set_eligibility_for_funding!
      Teachers::SetMentorFundingEligibility.new(
        teacher:,
        author:
      ).set!
    end

    def send_confirmation_email!
      return if email.blank?

      Schools::MentorRegistrationMailer.with(mentor_at_school_period:).confirmation.deliver_later
    end

    def record_event!
      Events::Record.record_teacher_registered_as_mentor_event!(author:, mentor_at_school_period:, teacher:, school:, training_period:, lead_provider:)

      if corrected_name.present?
        old_name = Teachers::Name.new(teacher).full_name_in_trs
        Events::Record.teacher_name_updated_by_user_event!(old_name:, new_name: corrected_name, author:, teacher:)
      end
    end

    alias_method :mentoring_at_new_school_only?, :mentoring_at_new_school_only
  end
end
