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

  def corrected_training_period_end_date(induction_record:)
    return induction_record.end_date if induction_record.end_date.present?

    participant_profile = induction_record.participant_profile
    corrected_date = nil

    # logic only initially for mentors with 1 induction record that has a blank end_date
    if participant_profile.mentor? && participant_profile.mentor_completion_date.present?
      if participant_profile.mentor_completion_date < SERVICE_START_DATE
        # set to the 31st August following the induction record start
        date = induction_record.start_date
        year = date.year
        year += 1 if date.month > 8
        corrected_date = Date.new(year, 8, 31)
      elsif participant_profile.mentor_completion_date > Date.new(2024, 1, 1)
        corrected_date = participant_profile.mentor_completion_date
      end
    end

    corrected_date
  end
end
