class PendingInductionSubmissionBatchPresenter < SimpleDelegator
  class MissingCSVDataError < StandardError; end

  # @raise [MissingCSVDataError]
  # @return [Array<Array>]
  def failed_submissions
    raise MissingCSVDataError, "No persisted CSV data found" if data.blank?

    failed_submissions = pending_induction_submissions.with_errors.pluck(:trn, :error_messages).to_h

    rows.filter_map do |row|
      errors = failed_submissions[row.sanitised_trn]
      row.with_errors(errors) if errors.present?
    end
  end

  # @return [String] downloadable CSV of failed submissions and their errors
  def to_csv
    CSV.generate(headers: row_headings.values, write_headers: true, force_quotes: true) do |csv|
      failed_submissions.each { |row| csv << row }
    end
  end
end
