class PendingInductionSubmissionBatch < ApplicationRecord
  CSV_HEADINGS = {
    trn: 'TRN',
    first_name: 'First name',
    last_name: 'Last name',
    dob: 'Date of birth',
    error: 'Error message', # FIXME: easier if this is mandatory and empty to start with

    # end_date: 'End date',
    # number_of_terms: 'Number of terms',
    # objective: 'Objective',
  }.freeze

  EMPTY_CELL = '-'.freeze

  class Row < Data.define(*CSV_HEADINGS.keys)
    include Enumerable

    def each(&block)
      to_a.each(&block)
    end

    def to_a
      CSV_HEADINGS.keys.map { |key| public_send(key) || EMPTY_CELL }
    end
  end

  # Associations
  belongs_to :appropriate_body
  has_many :pending_induction_submissions
  has_one_attached :csv_file

  enum :status, {
    pending: 'pending',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed'
  }

  # Download CSV Methods
  # ============================================================================

  # @return [Array<Array>] uploaded data with error reports
  def csv_download
    rows.map do |row|
      row_values = row.to_a
      row_values.delete_at(-1) # FIXME: last column might not be an error column

      [*row_values, pending_induction_submissions.find_by(trn: row.trn)&.error_message]
    end
  end

  # @return [String]
  def to_csv
    CSV.generate do |csv|
      csv << CSV_HEADINGS.keys
      csv_download.each { |row| csv << row }
    end
  end

  # Uploaded CSV Methods
  # ============================================================================

  # @return [CSV::Table<CSV::Row>] Uploaded CSV
  def data
    @data ||= CSV.parse(csv_file.download, headers: true)
  end

  # @return [Enumerator::Lazy<PendingInductionSubmissionBatch::Row>] Parsed data values
  def rows
    @rows ||= data.each.lazy.map { |row| Row.new(**row.to_h.symbolize_keys) }
  end

  # @return [Boolean]
  def has_valid_csv_headings?
    data.headers.eql?(CSV_HEADINGS.keys.map(&:to_s))
  end

  # @return [Boolean]
  def has_unique_trns?
    rows.map(&:trn).uniq.count.eql?(rows.count)
  end

  # @return [Boolean]
  def has_essential_csv_cells?
    # all TRNs present
    rows.map(&:trn).compact.count.eql?(rows.count)
  end

  # DB Only Methods
  # ============================================================================

  # @return [String]
  def error_message
    super || EMPTY_CELL
  end

  # @return [Array<Array>]
  def processed_rows
    pending_induction_submissions.map do |row|
      [
        row.trn,
        row.trs_first_name,
        row.trs_last_name,
        row.date_of_birth.to_fs(:govuk),
        row.error_message
      ]
    end
  end
end
