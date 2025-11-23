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

  # there are some mentors with a single IR record that has no end date - we want to set an end date in the following circumstances:
  #
  #   1. If mentor has a completion date < 1/9/2021, keep end date NULL for at_school period
  #   but set the training period end date to the next 31 August that follows their started date
  #
  #   2. If mentor has a completion date > 1/1/2024, keep end date NULL for at_school period but set the
  #   training period end date to match the mentor completion date
  #
  # For all other ECTs and mentors with one induction record and no end date, keep end date NULL.
  #
  def corrected_training_period_end_date(induction_record:, candidate_end_date:)
    participant_profile = induction_record.participant_profile
    return candidate_end_date if participant_profile.ect? || candidate_end_date.present?

    corrected_date = nil

    # logic only initially for mentors with 1 induction record that has a blank end_date
    if participant_profile.mentor? && participant_profile.mentor_completion_date.present?
      if participant_profile.mentor_completion_date < SERVICE_START_DATE
        # set to the 31st August following the induction record start
        date = induction_record.start_date
        year = date.year
        year += 1 if date.month > 8
        corrected_date = Date.new(year, 8, 31)
      elsif participant_profile.mentor_completion_date >= Date.new(2024, 1, 1)
        corrected_date = participant_profile.mentor_completion_date
      end
    end

    corrected_date
  end

  def corrected_end_date(induction_record, induction_records)
    return induction_record.updated_at if last_and_leaving_and_flipping_dates?(induction_record, induction_records)
    return induction_records.min_by(&:created_at).updated_at if two_induction_records_and_last_completed?(induction_records)

    induction_record.end_date
  end

private

  def last_created_induction_record(induction_records) = induction_records.max_by(&:created_at)

  def last_created_induction_record?(induction_record, induction_records)
    induction_record.id == last_created_induction_record(induction_records).id
  end

  def last_and_leaving_and_flipping_dates?(induction_record, induction_records)
    last_created_induction_record?(induction_record, induction_records) &&
      induction_record.leaving? &&
      induction_record.flipped_dates?
  end

  def two_induction_records?(induction_records) = induction_records.size == 2

  def two_induction_records_and_last_completed?(induction_records)
    two_induction_records?(induction_records) && last_created_induction_record(induction_records).completed?
  end
end
