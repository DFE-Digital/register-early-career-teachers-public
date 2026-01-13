class TeacherHistoryConverter::ECT::LatestInductionRecords
  include TeacherHistoryConverter::CalculatedAttributes

  attr_reader :induction_records

  def initialize(induction_records)
    @induction_records = induction_records
    @ect_at_school_periods = [] # ECF2TeacherHistory::ECTAtSchoolPeriodRow[]
  end

  def ect_at_school_periods
    induction_records.each_with_index do |induction_record, _i|
      @ect_at_school_periods = process(@ect_at_school_periods, induction_record)
    end

    @ect_at_school_periods
  end

private

  def process(ect_at_school_periods, induction_record)
    ect_at_school_periods << if (latest_ect_at_school_period = ect_at_school_periods&.last)
                               case
                               when induction_record.range_covers_finish_but_not_start?(*latest_ect_at_school_period.dates)
                                 latest_ect_at_school_period.finished_on = induction_record.start_date.to_date

                                 build_new_school_period_from_induction_record(induction_record)
                               else
                                 build_stub_school_period_prior_to(latest_ect_at_school_period, induction_record)
                               end
                             else
                               build_new_school_period_from_induction_record(induction_record)
                             end

    ect_at_school_periods.sort_by(&:started_on)
  end

  def build_new_school_period_from_induction_record(induction_record)
    ECF2TeacherHistory::ECTAtSchoolPeriodRow.new(
      started_on: induction_record.start_date.to_date,
      finished_on: induction_record.end_date&.to_date,
      school: induction_record.school,
      email: induction_record.preferred_identity_email,
      mentorship_period_rows: [],
      training_period_rows: [
        build_new_training_period_from_induction_record(induction_record)
      ]
    )
  end

  def build_stub_school_period_prior_to(school_period, induction_record)
    started_on = [school_period.started_on - 2.days, induction_record.start_date.to_date].min
    finished_on = school_period.started_on - 1.day

    training_period = build_new_training_period_from_induction_record(induction_record, { started_on:, finished_on: })

    ECF2TeacherHistory::ECTAtSchoolPeriodRow.new(
      started_on:,
      finished_on:,
      school: induction_record.school,
      email: induction_record.preferred_identity_email,
      mentorship_period_rows: [],
      training_period_rows: [
        training_period
      ]
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
