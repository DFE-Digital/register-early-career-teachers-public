class TeacherHistoryConverter::ECT::LatestInductionRecords
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
      ect_at_school_periods << ECF2TeacherHistory::ECTAtSchoolPeriodRow.new(
        started_on: induction_record.start_date.to_date,
        finished_on: induction_record.end_date&.to_date,
        school: induction_record.school,
        email: induction_record.preferred_identity_email,
        mentorship_period_rows: [],
        training_period_rows: []
      )
    end
    # Step 2:
    #
    # Training period - do we:
    # - extend an existing training period?
    # - create a new training period
    # - do nothing

    ect_at_school_periods
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
