class PendingInductionSubmissionBatchPresenter < SimpleDelegator
  class MissingCSVDataError < StandardError; end

  # @raise [MissingCSVDataError]
  # @return [Array<Array>]
  def failed_submissions
    raise MissingCSVDataError, "No persisted CSV data found" if data.blank?

    rows.filter_map do |row|
      failed_submission = pending_induction_submissions.with_errors.find_by(trn: row.trn)
      row.with_errors(failed_submission.error_message) if failed_submission.present?
    end
  end

  # @return [String] downloadable CSV of failed submissions and their errors
  def to_csv
    CSV.generate do |csv|
      csv << csv_headings.keys
      failed_submissions.each { |row| csv << row }
    end
  end

  # Temporary methods helpful for debugging during development
  # ============================================================================

  EMPTY_CELL = '-'.freeze

  def error_message
    super || EMPTY_CELL
  end

  def processed_headers
    common_headers = ['TRN', 'First name', 'Last name', 'Date of birth']
    if action?
      common_headers.push('End date', 'Number of terms', 'Objective', 'Error message')
    elsif claim?
      common_headers.push('Induction programme', 'Start date', 'Error message')
    end
  end

  def processed_rows
    pending_induction_submissions.map do |sub|
      common_rows = [
        sub.trn,
        sub.trs_first_name || EMPTY_CELL,
        sub.trs_last_name || EMPTY_CELL,
        sub.date_of_birth&.to_fs(:govuk) || EMPTY_CELL,
      ]

      if action?
        common_rows.push(
          sub.finished_on&.to_fs(:govuk) || EMPTY_CELL,
          sub.number_of_terms&.to_s || EMPTY_CELL,
          sub.outcome || EMPTY_CELL,
          sub.error_message
        )
      elsif claim?
        common_rows.push(
          ::INDUCTION_PROGRAMMES[sub.induction_programme&.to_sym] || EMPTY_CELL,
          sub.started_on&.to_fs(:govuk) || EMPTY_CELL,
          sub.error_message
        )
      end
    end
  end

  def ongoing_induction_periods
    InductionPeriod.where(appropriate_body:, finished_on: nil)
  end

  def submissions_with_induction_periods
    pending_induction_submissions.without_errors.map do |pending_induction_submission|
      [
        pending_induction_submission,
        pending_induction_submission.teacher.induction_periods.last
      ]
    end
  end
end
