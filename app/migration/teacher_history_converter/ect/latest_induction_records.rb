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
    # Step 1
    #
    # ECT at school period - do we:
    # - extend an existing ECT at school period?
    # - create a new ECT at school period?
    # - do nothing
    #
    school_period = ect_at_school_periods.find { |period| period.school.urn == induction_record.school.urn }
    if school_period.present?
      # check if returning to a school that the participant had left
      # i.e. this is not the same school period now it should be a new one
      #
      # otherwise
      #
      # handle changes to:
      # - training
      # - mentor
      # - cohort/schedule
      # - email address
      if school_period_covers_induction_record_period?(school_period, induction_record)
        # build_stub
      else
        # incorporate into period
      end
    else
      # this is a new period but is it contained by an existing one?
      covering_period = ect_at_school_periods.find do |period|
        school_period_covers_induction_record_period?(period, induction_record)
      end

      if covering_period.present?
        # add a stub school period
        ect_at_school_periods << build_stub_school_period_prior_to(covering_period, induction_record)
      else
        # add a new school period
        ect_at_school_periods << build_new_school_period_from_induction_record(induction_record)
      end
    end
    # Step 2: <- this maybe incorporated into the above?
    #
    # Training period - do we:
    # - extend an existing training period?
    # - create a new training period
    # - do nothing

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
      # started_on: induction_record.start_date.to_date,
      # finished_on: induction_record.end_date&.to_date,
      # created_at: induction_record.created_at,
      # school: induction_record.school,
      # training_programme: convert_training_programme_name(induction_record.training_programme),
      # lead_provider_info: induction_record.training_provider_info.lead_provider_info,
      # delivery_partner_info: induction_record.training_provider_info.delivery_partner_info,
      # contract_period_year: induction_record.cohort_year,
      # is_ect: true,
      # ecf_start_induction_record_id: induction_record.induction_record_id,
      # schedule_info: induction_record.schedule_info
    # )
  end

  def school_period_covers_induction_record_period?(school_period, induction_record)
    school_period_range = Range.new(school_period.started_on, school_period.finished_on)
    school_period_range.cover?(Range.new(induction_record.start_date, induction_record.end_date))
  end

  def build_training_period_rows(school_induction_records, all_induction_records)
    # training_period_rows = []
    # current_training = nil
    #
    # school_induction_records.each do |induction_record|
    #   index = all_induction_records.index(induction_record)
    #
    #   if training_changed?(current_training, induction_record)
    #     current_training = induction_record
    #     training_period_rows << ECF2TeacherHistory::TrainingPeriodRow.new(
    #       **ect_training_period_attributes(induction_record, school_induction_records, index),
    #       is_ect: true
    #     )
    #   else
    #     update_training_period_end_date(training_period_rows.last, induction_record, school_induction_records, :ect)
    #   end
    # end
    #
    # training_period_rows
  end
end
