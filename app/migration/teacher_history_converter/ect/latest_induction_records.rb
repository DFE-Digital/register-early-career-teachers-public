class TeacherHistoryConverter::ECT::LatestInductionRecords
  include TeacherHistoryConverter::CalculatedAttributes

  attr_reader :induction_records

  def initialize(induction_records)
    @induction_records = induction_records
    @ect_at_school_periods = [] # ECF2TeacherHistory::ECTAtSchoolPeriodRow[]
  end

  def ect_at_school_periods
    induction_records.each do |induction_record|
      @ect_at_school_periods = process(@ect_at_school_periods, induction_record)
    end

    @ect_at_school_periods
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
    started_on = [first_school_period&.started_on&.-(2.days), induction_record.start_date.to_date].compact.min
    finished_on = [first_school_period&.started_on&.-(1.day), induction_record.end_date&.to_date].compact.min
    training_period = build_new_training_period_from_induction_record(induction_record, { started_on:, finished_on: })

    ect_at_school_periods.unshift(
      ECF2TeacherHistory::ECTAtSchoolPeriodRow.new(
        started_on:,
        finished_on:,
        school: induction_record.school,
        email: induction_record.preferred_identity_email,
        mentorship_period_rows: [],
        training_period_rows: [training_period]
      )
    )
  end

  def build_new_training_period_from_induction_record(induction_record, overrides = {})
    training_attrs = {
      started_on: induction_record.start_date.to_date,
      finished_on: induction_record.end_date&.to_date,
      created_at: induction_record.created_at,
      school: induction_record.school,
      training_programme: convert_training_programme_name(induction_record.training_programme),
      lead_provider_info: induction_record.training_provider_info.lead_provider_info,
      delivery_partner_info: induction_record.training_provider_info.delivery_partner_info,
      contract_period_year: induction_record.cohort_year,
      is_ect: true,
      ecf_start_induction_record_id: induction_record.induction_record_id,
      schedule_info: induction_record.schedule_info
    }.merge(overrides)

    ECF2TeacherHistory::TrainingPeriodRow.new(**training_attrs)
  end
end
