class TeacherHistoryConverter::Mentor::AllInductionRecords
  include TeacherHistoryConverter::CalculatedAttributes

  attr_reader :trn, :profile_id, :induction_records, :states, :exclude_training_periods

  def initialize(trn:, profile_id:, induction_records:, states:, exclude_training_periods: false)
    @trn = trn
    @profile_id = profile_id
    @induction_records = induction_records
    @states = states
    @exclude_training_periods = exclude_training_periods
  end

  # Returns [ECF2TeacherHistory::MentorAtSchoolPeriod[], String[]]
  def mentor_at_school_periods
    @mentor_at_school_periods ||= induction_records
                                 .reverse
                                 .each_with_object([]) do |induction_record, periods|
                                   process(periods, induction_record)
                                 end
  end

private

  def process(mentor_at_school_periods, induction_record)
    started_on = induction_record.start_date
    finished_on = induction_record.end_date

    # we do not want to add training periods for ERO mentors (unless they have paid or clawed_back declarations)
    training_period = build_training_period(induction_record, { started_on:, finished_on: }) unless exclude_training_periods

    mentor_at_school_periods.unshift(
      ECF2TeacherHistory::MentorAtSchoolPeriod.new(
        started_on:,
        finished_on:,
        school: induction_record.school,
        email: induction_record.preferred_identity_email,
        training_periods: [training_period].compact
      )
    )
  end

  def build_training_period(induction_record, overrides = {})
    training_programme = convert_training_programme_name(induction_record.training_programme)
    return if training_programme != "provider_led"

    training_provider_info = induction_record.training_provider_info

    raise(StandardError, "No training provider info for #{induction_record.induction_record_id}") if training_provider_info.nil?

    training_attrs = {
      started_on: induction_record.start_date,
      finished_on: induction_record.end_date,
      created_at: induction_record.created_at,
      school: induction_record.school,
      training_programme:,
      lead_provider_info: training_provider_info&.lead_provider_info,
      delivery_partner_info: training_provider_info&.delivery_partner_info,
      contract_period_year: induction_record.cohort_year,
      is_ect: false,
      ecf_start_induction_record_id: induction_record.induction_record_id,
      schedule_info: induction_record.schedule_info,
      combination: build_combination(induction_record:, training_programme:),
      **withdrawal_data(
        training_status: induction_record.training_status,
        lead_provider_id: training_provider_info&.lead_provider_info&.ecf1_id
      )
    }.merge(overrides)

    ECF2TeacherHistory::TrainingPeriod.new(**training_attrs)
  end

  def build_combination(induction_record:, **overrides)
    ECF2TeacherHistory::Combination
      .from_induction_record(trn:, profile_id:, profile_type: "mentor", induction_record:, **overrides)
  end

  def withdrawal_data(training_status:, lead_provider_id:)
    TeacherHistoryConverter::WithdrawalData.new(training_status:, states:, lead_provider_id:).withdrawal_data
  end
end
