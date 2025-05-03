class PendingInductionSubmissionBatchPresenter < SimpleDelegator
  class MissingCSVDataError < StandardError; end

  # @raise [MissingCSVDataError]
  # @return [Array<Array>]
  def failed_submissions
    raise MissingCSVDataError, "No persisted CSV data found" if data.blank?

    rows.filter_map do |row|
      failed_submission = pending_induction_submissions.with_errors.find_by(trn: row.sanitised_trn)
      row.with_errors(failed_submission.error_messages) if failed_submission.present?
    end
  end

  # @return [String] downloadable CSV of failed submissions and their errors
  def to_csv
    CSV.generate do |csv|
      csv << row_headings.values
      failed_submissions.each { |row| csv << row }
    end
  end

  # Temporary method helpful for debugging during development
  def processed_headers
    common_headers = ['TRN', 'First name', 'Last name', 'Date of birth']
    if action?
      common_headers.push('Induction end date', 'Number of terms', 'Outcome', 'Error messages')
    elsif claim?
      common_headers.push('Induction programme', 'Induction start date', 'Error messages')
    end
  end

  # Temporary method helpful for debugging during development
  def processed_rows
    pending_induction_submissions.map do |sub|
      common_rows = [
        sub.trn,
        sub.trs_first_name || '-',
        sub.trs_last_name || '-',
        sub.date_of_birth&.to_fs(:govuk) || '-',
      ]

      if action?
        common_rows.push(
          sub.finished_on&.to_fs(:govuk) || '-',
          sub.number_of_terms&.to_s || '-',
          sub.outcome || '-',
          sub.error_messages.empty? ? "✅" : sub.error_messages.count.to_s
        )
      elsif claim?
        common_rows.push(
          ::INDUCTION_PROGRAMMES[sub.induction_programme&.to_sym] || '-',
          sub.started_on&.to_fs(:govuk) || '-',
          sub.error_messages.empty? ? "✅" : sub.error_messages.count.to_s
        )
      end
    end
  end

  # Temporary method helpful for debugging during development
  def ongoing_induction_periods
    InductionPeriod.where(appropriate_body:, finished_on: nil)
  end

  # Temporary method helpful for debugging during development
  def submissions_with_induction_periods
    pending_induction_submissions.without_errors.map do |pending_induction_submission|
      [
        pending_induction_submission,
        pending_induction_submission&.teacher&.induction_periods&.last
      ]
    end
  end
end
