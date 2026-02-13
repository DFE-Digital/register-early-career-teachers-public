# From all the induction records of a participant received in the converter, the latest induction records mode will
# group them by (school, lead provider, cohort) and select the one unfinished or the most recently created one.
# The resulting list will be sorted by start_date, created_at, unfinished last and them converted to ect at school periods.
# See TeacherHistoryConverter::CalculatedFields.
class TeacherHistoryConverter::ECT::LatestInductionRecords
  include TeacherHistoryConverter::CalculatedAttributes

  attr_reader :trn, :profile_id, :induction_records, :mentor_at_school_periods, :states

  def initialize(trn:, profile_id:, induction_records:, mentor_at_school_periods:, states:)
    @trn = trn
    @profile_id = profile_id
    @induction_records = latest_induction_records(induction_records:)
    @mentor_at_school_periods = mentor_at_school_periods
    @states = states
  end

  # Returns [ECF2TeacherHistory::ECTAtSchoolPeriod[], String[]]
  def ect_at_school_periods
    @ect_at_school_periods ||= induction_records
                                 .reverse
                                 .each_with_object([]) do |induction_record, periods|
                                   process(periods, induction_record)
    end
  end

private

  # Add a new school_period period to the beginning of ect_at_school_periods with:
  #  - start_date: the earliest of the induction_record.start_date and the first school_period start_date - 2.days
  #  - end_date: the earliest of the induction_record.end_date and the first school_period start_date - 1.day
  #
  # This is so that we are either creating:
  #  - a mirror school_period from the induction record if their dates range are before the first school_period dates
  #  - a truncated school_period from the induction record if their dates cover only the start_date of the first school_period dates
  #  - a stub school_period from the induction record if its start date is covered by the first school period
  #
  # We can't have an induction_period past the first school_period because the induction records (and therefore the
  #   school period out of them are received in reverse order of start_date)
  def process(ect_at_school_periods, induction_record)
    first_school_period = ect_at_school_periods.first
    started_on = [first_school_period&.started_on&.-(2.days), induction_record.start_date].compact.min
    finished_on = [first_school_period&.started_on&.-(1.day), induction_record.end_date].compact.min
    training_period = build_training_period(induction_record:, started_on:, finished_on:)

    # Only create mentorship for the last ect at school period if its associated induction record has mentor profile
    if first_school_period.nil? && induction_record.mentor_profile_id
      mentorship_period = build_mentorship_period(induction_record:,
                                                  ect_started_on: started_on,
                                                  ect_finished_on: finished_on)
    end

    ect_at_school_periods.unshift(
      ECF2TeacherHistory::ECTAtSchoolPeriod.new(
        started_on:,
        finished_on:,
        school: induction_record.school,
        email: induction_record.preferred_identity_email,
        mentorship_periods: [mentorship_period].compact,
        training_periods: [training_period].compact
      )
    )
  end

  def build_mentorship_period(induction_record:, ect_started_on:, ect_finished_on:)
    mentor_at_school_period = find_overlapping_mentor_period(started_on: ect_started_on,
                                                             finished_on: ect_finished_on,
                                                             mentor_profile_id: induction_record.mentor_profile_id,
                                                             urn: induction_record.school.urn)

    if mentor_at_school_period
      mentor_started_on = mentor_at_school_period.started_on
      mentor_finished_on = mentor_at_school_period.finished_on

      mentorship_started_on = [ect_started_on, mentor_started_on].max
      mentorship_finished_on = [ect_finished_on, mentor_finished_on].compact.min

      ECF2TeacherHistory::MentorshipPeriod.new(
        started_on: mentorship_started_on,
        finished_on: mentorship_finished_on,
        ecf_start_induction_record_id: induction_record.induction_record_id,
        ecf_end_induction_record_id: induction_record.induction_record_id,
        mentor_at_school_period_id: mentor_at_school_period.mentor_at_school_period_id,
        api_ect_training_record_id: profile_id,
        api_mentor_training_record_id: mentor_at_school_period.teacher.api_mentor_training_record_id
      )
    end
  end

  def build_training_period(induction_record:, **overrides)
    training_programme = convert_training_programme_name(induction_record.training_programme)

    training_attrs = {
      started_on: induction_record.start_date,
      finished_on: induction_record.end_date,
      created_at: induction_record.created_at,
      school: induction_record.school,
      training_programme:,
      lead_provider_info: induction_record.training_provider_info&.lead_provider_info,
      delivery_partner_info: induction_record.training_provider_info&.delivery_partner_info,
      contract_period_year: induction_record.cohort_year,
      is_ect: true,
      ecf_start_induction_record_id: induction_record.induction_record_id,
      schedule_info: induction_record.schedule_info,
      combination: build_combination(induction_record:, training_programme:),
      **withdrawal_data(training_status: induction_record.training_status)
    }.merge(overrides)

    training_attrs.except!(:lead_provider_info, :delivery_partner_info, :schedule_info) if training_programme == "school_led"

    ECF2TeacherHistory::TrainingPeriod.new(**training_attrs)
  end

  def build_combination(induction_record:, **overrides)
    ECF2TeacherHistory::Combination
      .from_induction_record(trn:, profile_id:, profile_type: "ect", induction_record:, **overrides)
  end

  # Find the last MentorAtSchoolPeriod overlapping started_on..finished_on for the teacher and school identifiers given
  def find_overlapping_mentor_period(started_on:, finished_on:, mentor_profile_id:, urn:)
    overlapping_mentor_periods = mentor_at_school_periods.select do
      it.school.urn.to_i == urn.to_i &&
        it.teacher.api_mentor_training_record_id == mentor_profile_id &&
        it.range.overlaps?(started_on..finished_on)
    end

    OVERLAPPING_MENTOR_PERIODS_SORTING.call(overlapping_mentor_periods).last
  end

  def withdrawal_data(training_status:)
    TeacherHistoryConverter::WithdrawalData.new(training_status:, states:).withdrawal_data
  end
end
