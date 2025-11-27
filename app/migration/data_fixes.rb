module DataFixes
  INDUCTION_RECORDS_ADDED_DATE = Date.new(2022, 2, 9)
  SERVICE_START_DATE = Date.new(2021, 9, 1)

  # NOTE: this doesn't account for induction record groups so will set the start
  # for the first of each group
  def corrected_start_date(induction_record:, sequence_number:)
    if sequence_number.zero?
      if induction_record.start_date.to_date == INDUCTION_RECORDS_ADDED_DATE
        Date.new(2021, 9, 1)
      else
        [induction_record.start_date, induction_record.created_at].min
      end
    else
      induction_record.start_date
    end
  end

  def corrected_training_period_end_date(induction_record:, induction_records:, candidate_end_date:)
    participant_profile = induction_record.participant_profile

    return candidate_end_date if induction_records.count > 1
    return candidate_end_date if participant_profile.ect?
    return candidate_end_date if candidate_end_date.present?
    return unless participant_profile.mentor?

    date_for_mentors_with_one_ir(induction_record)
  end

  def corrected_end_date(induction_record, induction_records)
    return induction_record.updated_at if last_and_leaving_and_flipping_dates?(induction_record, induction_records)
    return first_created_induction_record(induction_records).updated_at if two_induction_records_and_last_completed?(induction_records)

    induction_record.end_date
  end

private

  # there are some mentors with a single IR record that has no end date - we want to set an end date in the following circumstances:
  #
  #   1. If mentor has a completion date < 1/9/2021, keep end date NULL for at_school period
  #   but set the training period end date to the next 31 August that follows their started date
  #
  #   2. If mentor has a completion date >= 1/9/2021, keep end date NULL for at_school period but set the
  #   training period end date to the next 31 August that follows their completion date
  #
  # For all other mentors with one induction record and no end date, keep end date NULL.
  #
  def date_for_mentors_with_one_ir(induction_record)
    completion_date = induction_record.participant_profile.mentor_completion_date
    return if completion_date.blank?
    return the_31st_august_following(induction_record.start_date) if completion_date < SERVICE_START_DATE

    the_31st_august_following(completion_date)
  end

  def first_created_induction_record(induction_records) = induction_records.min_by(&:created_at)

  def last_created_induction_record(induction_records) = induction_records.max_by(&:created_at)

  def last_created_induction_record?(induction_record, induction_records)
    induction_record.id == last_created_induction_record(induction_records).id
  end

  def last_and_leaving_and_flipping_dates?(induction_record, induction_records)
    last_created_induction_record?(induction_record, induction_records) &&
      induction_record.leaving? &&
      induction_record.flipped_dates?
  end

  def two_induction_records?(induction_records) = induction_records.count == 2

  def two_induction_records_and_last_completed?(induction_records)
    two_induction_records?(induction_records) && last_created_induction_record(induction_records).completed?
  end

  def the_31st_august_following(date)
    year = date.month > 8 ? date.year + 1 : date.year
    Date.new(year, 8, 31)
  end
end
