class TeacherHistoryConverter::DateCorrector
  # Date when induction records were added to ECF - records with this start date
  # should use SERVICE_START_DATE instead
  INDUCTION_RECORDS_ADDED_DATE = Date.new(2022, 2, 9)
  SERVICE_START_DATE = Date.new(2021, 9, 1)

  attr_reader :ect_induction_completion_date, :mentor_completion_date

  def initialize(ect_induction_completion_date:, mentor_completion_date:)
    @ect_induction_completion_date = ect_induction_completion_date
    @mentor_completion_date = mentor_completion_date
  end

  # Corrects start dates for induction records
  # - For first IR: if start_date == 2022-02-09 (when IRs were added), use 2021-09-01
  # - Otherwise use min of start_date and created_at
  # - For subsequent records: just use start_date
  def corrected_start_date(induction_record, sequence_number)
    date = if sequence_number.zero?
             if induction_record.start_date.to_date == INDUCTION_RECORDS_ADDED_DATE
               SERVICE_START_DATE
             else
               [induction_record.start_date, induction_record.created_at.to_date].min
             end
           else
             induction_record.start_date
           end

    date.to_date
  end

  # Corrects end dates for school periods (ECTAtSchoolPeriod/MentorAtSchoolPeriod)
  def corrected_end_date(induction_record, induction_records, participant_type:)
    if participant_type == :ect && ect_with_more_than_2_irs_and_completion_date?(induction_records)
      if last_created_induction_record?(induction_record, induction_records)
        return ect_induction_completion_date&.to_date
      end

      return [induction_record.end_date&.to_date, ect_induction_completion_date&.to_date].compact.min
    end

    return induction_record.updated_at.to_date if last_and_leaving_and_flipping_dates?(induction_record, induction_records)
    return first_created_induction_record(induction_records).updated_at.to_date if two_induction_records_and_last_completed?(induction_records)

    induction_record.end_date&.to_date
  end

  # Corrects end dates for training periods
  def corrected_training_period_end_date(induction_record, induction_records, participant_type:)
    candidate_end_date = induction_record.end_date&.to_date

    return first_created_induction_record(induction_records).end_date if two_irs_at_a_school_and_only_last_deferred_or_withdrawn?(induction_records)
    return candidate_end_date if induction_records.count > 1
    return candidate_end_date if participant_type == :ect
    return candidate_end_date if candidate_end_date.present?
    return unless participant_type == :mentor

    date_for_mentors_with_one_ir(induction_record)
  end

private

  # For mentors with a single IR and no end date:
  # - If mentor has completion_date < 1/9/2021, use 31 August following start_date
  # - If mentor has completion_date >= 1/9/2021, use 31 August following completion_date
  def date_for_mentors_with_one_ir(induction_record)
    return if mentor_completion_date.blank?
    return the_31st_august_following(induction_record.start_date) if mentor_completion_date < SERVICE_START_DATE

    the_31st_august_following(mentor_completion_date)
  end

  def the_31st_august_following(date)
    year = date.month > 8 ? date.year + 1 : date.year
    Date.new(year, 8, 31)
  end

  def ect_with_more_than_2_irs_and_completion_date?(induction_records)
    return false unless induction_records.count > 2

    ect_induction_completion_date.present?
  end

  def first_created_induction_record(induction_records)
    induction_records.min_by(&:created_at)
  end

  def last_created_induction_record(induction_records)
    induction_records.max_by(&:created_at)
  end

  def last_created_induction_record?(induction_record, induction_records)
    induction_record.induction_record_id == last_created_induction_record(induction_records).induction_record_id
  end

  def last_and_leaving_and_flipping_dates?(induction_record, induction_records)
    last_created_induction_record?(induction_record, induction_records) &&
      leaving?(induction_record) &&
      flipped_dates?(induction_record)
  end

  def two_induction_records?(induction_records)
    induction_records.count == 2
  end

  def two_induction_records_and_last_completed?(induction_records)
    two_induction_records?(induction_records) && completed?(last_created_induction_record(induction_records))
  end

  def two_irs_at_a_school_and_only_last_deferred_or_withdrawn?(induction_records)
    return false unless two_induction_records?(induction_records)

    first_induction_record = first_created_induction_record(induction_records)
    second_induction_record = last_created_induction_record(induction_records)

    return false if deferred?(first_induction_record)
    return false if withdrawn?(first_induction_record)

    deferred?(second_induction_record) || withdrawn?(second_induction_record)
  end

  # Induction record status helpers
  def leaving?(induction_record)
    induction_record.induction_status == "leaving"
  end

  def completed?(induction_record)
    induction_record.induction_status == "completed"
  end

  def deferred?(induction_record)
    induction_record.training_status == "deferred"
  end

  def withdrawn?(induction_record)
    induction_record.training_status == "withdrawn"
  end

  def flipped_dates?(induction_record)
    return false if induction_record.start_date.blank? || induction_record.end_date.blank?

    induction_record.start_date > induction_record.end_date
  end
end
