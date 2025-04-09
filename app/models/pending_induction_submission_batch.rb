class PendingInductionSubmissionBatch < ApplicationRecord
  EMPTY_CELL = '-'.freeze

  def self.new_claim_for(appropriate_body:, **)
    new(appropriate_body:, batch_type: 'claim', **)
  end

  def self.new_action_for(appropriate_body:, **)
    new(appropriate_body:, batch_type: 'action', **)
  end

  CLAIM_CSV_HEADINGS = {
    trn: 'TRN',
    dob: 'Date of birth',
    induction_programme: 'Induction programme',
    start_date: 'Start date',
    error: 'Error message',
  }.freeze

  ACTION_CSV_HEADINGS = {
    trn: 'TRN',
    dob: 'Date of birth',
    end_date: 'End date',
    number_of_terms: 'Number of terms',
    objective: 'Objective',
    error: 'Error message',
  }.freeze

  class ActionRow < Data.define(*ACTION_CSV_HEADINGS.keys)
    include Enumerable

    def each(&block)
      to_a.each(&block)
    end

    # Guard against "André" Encoding::CompatibilityError
    def to_a
      members.map do |key|
        public_send(key).dup&.force_encoding("UTF-8") || EMPTY_CELL
      end
    end
  end

  class ClaimRow < Data.define(*CLAIM_CSV_HEADINGS.keys)
    include Enumerable

    def each(&block)
      to_a.each(&block)
    end

    # Guard against "André" Encoding::CompatibilityError
    def to_a
      members.map do |key|
        public_send(key).dup&.force_encoding("UTF-8") || EMPTY_CELL
      end
    end
  end

  # Associations
  belongs_to :appropriate_body
  has_many :pending_induction_submissions
  has_one_attached :csv_file

  enum :batch_status, {
    pending: 'pending',
    processing: 'processing',
    processed: 'processed',
    completed: 'completed',
    failed: 'failed'
  }

  enum :batch_type, {
    action: 'action',
    claim: 'claim'
  }

  # Scopes
  scope :for_appropriate_body, ->(appropriate_body) { where(appropriate_body:) }

  # Validations
  validates :batch_status, presence: true
  validates :batch_type, presence: true
  validate :csv_mime_type

  # CSV content validations
  validate :wrong_headers, on: :uploaded
  validate :unique_trns, on: :uploaded
  validate :missing_trns, on: :uploaded
  validate :missing_dobs, on: :uploaded
  validate :iso8601_date, on: :uploaded

  # Download CSV Methods
  # ============================================================================

  def csv_headings
    if action?
      ACTION_CSV_HEADINGS
    elsif claim?
      CLAIM_CSV_HEADINGS
    end
  end

  # @return [Array<Array>] uploaded data with error reports
  def csv_download
    @csv_download ||= rows.map { |row|
      next unless failed_trns.include?(row.trn)

      error_message = pending_induction_submissions.find_by(trn: row.trn)&.error_message || EMPTY_CELL

      row_values = row.to_a
      row_values.delete_at(-1)
      row_values.push(error_message)
    }.compact
  end

  # @return [String]
  def to_csv
    CSV.generate do |csv|
      csv << csv_headings.keys
      csv_download.each { |row| csv << row }
    end
  end

  def failed_trns
    pending_induction_submissions.where.not(error_message: [nil, '']).map(&:trn)
  end

  # Uploaded CSV Methods
  # ============================================================================

  # FIXME: Octothorpes are used to prefix comments in the CSV file for easier testing (remove when no longer helpful)
  # @return [CSV::Table<CSV::Row>] Hash-like with headers
  def data
    # @data ||= CSV.parse(csv_file.download, headers: true, converters: %i[numeric date])
    @data ||= CSV.parse(csv_file.download, headers: true, skip_lines: /^#/)
  end

  # @return [Enumerator::Lazy<PendingInductionSubmissionBatch::Row>] Struct-like without headers
  def rows
    @rows ||= data.each.lazy.map { |row| row_class.new(**row.to_h.symbolize_keys) }
  end

  def row_class
    if action?
      ActionRow
    elsif claim?
      ClaimRow
    end
  end

  # @return [Boolean]
  def has_valid_csv_headings?
    data.headers.eql?(csv_headings.keys.map(&:to_s))
  end

  # @return [Boolean]
  def has_unique_trns?
    rows.map(&:trn).uniq.count.eql?(rows.count)
  end

  # @return [Boolean]
  def has_trns?
    rows.map(&:trn).compact.count.eql?(rows.count)
  end

  # @return [Boolean]
  def has_dates_of_birth?
    rows.map(&:dob).compact.count.eql?(rows.count)
  end

  # @return [Boolean]
  def has_valid_csv_dates?
    rows.all? do |r|
      dates = [r.dob]
      dates.push(r.start_date) if claim?
      dates.push(r.end_date) if action?
      dates.all? { |raw_value| Date.iso8601(raw_value) }
    end
  rescue Date::Error
    false
  end

  # DB Only Methods
  # ============================================================================

  # @return [String]
  def error_message
    super || EMPTY_CELL
  end

  # @return [Array<String>]
  def processed_headers
    common_headers = ['TRN', 'First name', 'Last name', 'Date of birth']
    if action?
      common_headers.push('End date', 'Number of terms', 'Objective', 'Error message')
    elsif claim?
      common_headers.push('Induction programme', 'Start date', 'Error message')
    end
  end

  # @return [Array<Array>]
  def processed_rows
    pending_induction_submissions.map do |row|
      common_rows = [
        row.trn,
        row.trs_first_name || EMPTY_CELL,
        row.trs_last_name || EMPTY_CELL,
        row.date_of_birth&.to_fs(:govuk) || EMPTY_CELL,
      ]

      if action?
        common_rows.push(
          row.finished_on&.to_fs(:govuk) || EMPTY_CELL,
          row.number_of_terms&.to_s || EMPTY_CELL,
          row.outcome || EMPTY_CELL,
          row.error_message
        )
      elsif claim?
        common_rows.push(
          ::INDUCTION_PROGRAMMES[row.induction_programme&.to_sym] || EMPTY_CELL,
          row.started_on&.to_fs(:govuk) || EMPTY_CELL,
          row.error_message
        )
      end
    end
  end

  # @return [Array<Array>]
  def submissions_with_induction_periods
    pending_induction_submissions.without_errors.map do |pending_induction_submission|
      [pending_induction_submission, Teacher.find_by(trn: pending_induction_submission.trn).induction_periods.last]
    end
  end

private

  def wrong_headers
    errors.add(:csv_file, "CSV file contains unsupported columns") unless has_valid_csv_headings?
  end

  def unique_trns
    errors.add(:csv_file, "CSV file contains duplicate TRNs") unless has_unique_trns?
  end

  def missing_trns
    errors.add(:csv_file, "CSV file contains missing TRNs") unless has_trns?
  end

  def missing_dobs
    errors.add(:csv_file, "CSV file contains missing dates of birth") unless has_dates_of_birth?
  end

  def iso8601_date
    errors.add(:csv_file, "CSV file contains unsupported date format") unless has_valid_csv_dates?
  end

  def csv_mime_type
    errors.add(:csv_file, 'File type must be a CSV') if csv_file.attached? && !csv_file.content_type.in?(%w[text/csv])
  end
end
