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
    if ect_at_school_periods.empty?
      ect_at_school_periods << build_new_school_period_from_induction_record(induction_record)
    else
      # Need to handle:
      # - induction record at same school as last added period
      # - induction record at different school from last added period
      # - induction record at different school from last but matching a previously added period
      last_school_period = ect_at_school_periods.last
      if induction_record.school.urn == last_school_period.school.urn
        # handle changes to:
        # - training
        # - mentor
        # - cohort/schedule
        # - email address
      else
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
        else
          # add a new school period
        end
      end
    end
    # Step 2:
    #
    # Training period - do we:
    # - extend an existing training period?
    # - create a new training period
    # - do nothing

    ect_at_school_periods
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

  def build_new_training_period_from_induction_record(induction_record)
    ECF2TeacherHistory::TrainingPeriodRow.new(
      started_on: induction_record.start_date.to_date,
      finished_on: induction_record.end_date&.to_date,
      created_at: induction_record.created_at,
      school: induction_record.school,
      training_programme: convert_training_programme_name(induction_record.training_programme),
      lead_provider_info: induction_record.training_provider_info.lead_provider_info,
      delivery_partner_info: induction_record.training_provider_info.delivery_partner_info,
      contract_period_year: induction_record.cohort_year,
      is_ect: true,
      ecf_start_induction_record_id: induction_record.induction_record_id
    )
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
