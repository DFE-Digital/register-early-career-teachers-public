class PendingInductionSubmissionBatch < ApplicationRecord
  CSV_HEADINGS = {
    trn: 'TRN',
    dob: 'Date of birth',
    # induction_programme: 'Induction programme',
    # start_date: 'Start date',
    end_date: 'End date',
    number_of_terms: 'Number of terms',
    objective: 'Objective',
    error: 'Error message', # FIXME: easier if this is mandatory and empty to start with
  }.freeze

  EMPTY_CELL = '-'.freeze

  class Row < Data.define(*CSV_HEADINGS.keys)
    include Enumerable

    def each(&block)
      to_a.each(&block)
    end

    # Guard against "André" Encoding::CompatibilityError
    def to_a
      CSV_HEADINGS.keys.map do |key|
        public_send(key).dup&.force_encoding("UTF-8") || EMPTY_CELL
      end
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

  # Validations
  validate :wrong_headers, on: :uploaded
  validate :unique_trns, on: :uploaded
  validate :missing_trns, on: :uploaded

  def wrong_headers
    errors.add(:csv_file, "CSV file contains unsupported columns") unless has_valid_csv_headings?
  end

  def unique_trns
    errors.add(:csv_file, "CSV file contains duplicate TRNs") unless has_unique_trns?
  end

  def missing_trns
    errors.add(:csv_file, "CSV file contains missing TRNs") unless has_essential_csv_cells?
  end

  # Download CSV Methods
  # ============================================================================

  # @return [Array<Array>] uploaded data with error reports
  def csv_download
    @csv_download ||= rows.map { |row|
      row_values = row.to_a

      next unless failed_trns.include?(row.trn)

      # if rows last column header is errors?
      row_values.delete_at(-1) # FIXME: last column might not be an error column

      [
        *row_values,
        pending_induction_submissions.find_by(trn: row.trn)&.error_message || EMPTY_CELL
      ]
      # else
      #   row_values
      # end
    }.compact
  end

  # @return [String]
  def to_csv
    CSV.generate do |csv|
      csv << CSV_HEADINGS.keys
      csv_download.each { |row| csv << row }
    end
  end

  def failed_trns
    pending_induction_submissions.where.not(error_message: [nil, '']).map(&:trn)
  end

  # Uploaded CSV Methods
  # ============================================================================

  # @return [CSV::Table<CSV::Row>] Hash-like with headers
  def data
    # @data ||= CSV.parse(csv_file.download, headers: true, converters: %i[numeric date])
    @data ||= CSV.parse(csv_file.download, headers: true, skip_lines: /^#/)
  end

  # @return [Enumerator::Lazy<PendingInductionSubmissionBatch::Row>] Struct-like without headers
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

  def processed_headers
    ['TRN', 'First name', 'Last name', 'Date of birth', 'End date', 'Number of terms', 'Objective', 'Error message']
  end

  # @return [Array<Array>]
  def processed_rows
    pending_induction_submissions.map do |row|
      [
        row.trn,
        row.trs_first_name || EMPTY_CELL,
        row.trs_last_name || EMPTY_CELL,
        row.date_of_birth&.to_fs(:govuk) || EMPTY_CELL,
        row.finished_on&.to_fs(:govuk) || EMPTY_CELL,
        row.number_of_terms&.to_s || EMPTY_CELL,
        row.outcome || EMPTY_CELL,
        row.error_message
      ]
    end
  end
end
