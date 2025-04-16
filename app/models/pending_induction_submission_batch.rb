class PendingInductionSubmissionBatch < ApplicationRecord
  # Class methods
  # @return [PendingInductionSubmissionBatch] type "claim"
  def self.new_claim_for(appropriate_body:, **)
    new(appropriate_body:, batch_type: 'claim', **)
  end

  # @return [PendingInductionSubmissionBatch] type "action"
  def self.new_action_for(appropriate_body:, **)
    new(appropriate_body:, batch_type: 'action', **)
  end

  # @return [Class] A class that represents a row in the CSV file
  # @param columns [Array<Symbol>] Array of CSV column headings
  def self.build_row_class(columns)
    Data.define(*columns) do
      include Enumerable

      # @return [Array<String>]
      def with_errors(error_message)
        row_values = to_a
        row_values.delete_at(-1)
        row_values.push(error_message)
      end

      # @return [Enumerable]
      def each(&block)
        to_a.each(&block)
      end

      # Guards against Encoding::CompatibilityError i.e. "André"
      # @return [Array<String>] encoded values for the row or placeholder
      def to_a
        members.map do |key|
          public_send(key).dup&.force_encoding("UTF-8")
        end
      end
    end
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

  ActionRow = build_row_class(ACTION_CSV_HEADINGS.keys)
  ClaimRow = build_row_class(CLAIM_CSV_HEADINGS.keys)

  # Associations
  belongs_to :appropriate_body
  has_many :pending_induction_submissions
  has_one_attached :csv_file

  # Callbacks
  after_commit :data_from_csv

  # Enums
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

  # Methods

  # @return [Hash] CSV headings
  def csv_headings
    return ACTION_CSV_HEADINGS if action?

    CLAIM_CSV_HEADINGS if claim?
  end

  # @raise [ActiveStorage::FileNotFoundError]
  # @return [CSV::Table<CSV::Row>] Hash-like with headers
  def from_csv
    # Octothorpes are used to prepend commented lines for testing purposes (remove when no longer helpful)
    @from_csv ||= CSV.parse(csv_file.download, headers: true, skip_lines: /^#/)
  end

  # @return [Enumerator::Lazy<PendingInductionSubmissionBatch::ClaimRow, PendingInductionSubmissionBatch::ActionRow>] Struct-like without headers
  def rows
    (data || from_csv).each.lazy.map { |row| row_class.new(**row.to_h.symbolize_keys) }
  end

private

  # @return [nil]
  def data_from_csv
    return unless csv_file.attached? && valid?(:uploaded) && data.blank?

    csv_file.purge if update!(data: from_csv.map(&:to_h))
  end

  # @return [PendingInductionSubmissionBatch::ActionRow, PendingInductionSubmissionBatch::ClaimRow]
  def row_class
    return ActionRow if action?

    ClaimRow if claim?
  end

  # add file size validation
  # add row limit validation

  def wrong_headers
    errors.add(:csv_file, "CSV file contains unsupported columns") unless has_valid_csv_headings?
  end

  # move to row-level validation
  def unique_trns
    errors.add(:csv_file, "CSV file contains duplicate TRNs") unless has_unique_trns?
  end

  # move to row-level validation
  def missing_trns
    errors.add(:csv_file, "CSV file contains missing TRNs") unless has_trns?
  end

  # move to row-level validation
  def missing_dobs
    errors.add(:csv_file, "CSV file contains missing dates of birth") unless has_dates_of_birth?
  end

  # move to row-level validation
  def iso8601_date
    errors.add(:csv_file, "CSV file contains unsupported date format") unless has_valid_csv_dates?
  end

  def csv_mime_type
    errors.add(:csv_file, 'File type must be a CSV') if csv_file.attached? && !csv_file.content_type.in?(%w[text/csv])
  end

  # @return [Boolean] against file on disk
  def has_valid_csv_headings?
    from_csv.headers.sort.eql?(csv_headings.keys.sort.map(&:to_s))
  end

  # @return [Boolean] against file on disk
  def has_unique_trns?
    rows.map(&:trn).uniq.count.eql?(rows.count)
  end

  # @return [Boolean] against file on disk
  def has_trns?
    rows.map(&:trn).compact.count.eql?(rows.count)
  end

  # @return [Boolean] against file on disk
  def has_dates_of_birth?
    rows.map(&:dob).compact.count.eql?(rows.count)
  end

  # OPTIMIZE: refactor date validation into Data classes
  # @return [Boolean] against file on disk
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
end
