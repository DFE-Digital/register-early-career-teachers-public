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

      # @return [Boolean]
      def invalid_trn?
        trn !~ /\A\d{7}\z/
      end

      # all cells except "error" have content
      # @return [Boolean]
      def blank_cell?
        members[0..-2].any? { |key| public_send(key).blank? }
      end

      # date cells are formatted as YYYY-MM-DD
      # @return [Boolean]
      def invalid_date?
        members.grep(/dob|_date/).any? do |key|
          !Date.iso8601(public_send(key))
        rescue Date::Error
          true
        end
      end

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
      # @return [Array<String>] encoded values for the row
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

  # CSV-level validations
  validate :csv_mime_type
  validate :csv_file_size
  validate :wrong_headers, on: :uploaded
  validate :row_count, on: :uploaded
  validate :unique_trns, on: :uploaded

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

  def csv_mime_type
    errors.add(:csv_file, 'File type must be a CSV') if csv_file.attached? && !csv_file.content_type.in?(%w[text/csv])
  end

  def csv_file_size
    errors.add(:csv_file, 'File size must be less than 1MB') if csv_file.attached? && csv_file.byte_size > 1.megabyte
  end

  def wrong_headers
    errors.add(:csv_file, 'CSV file contains unsupported columns') unless has_valid_csv_headings?
  end

  def row_count
    errors.add(:csv_file, 'CSV file contains too many rows') if from_csv.count > 1000
  end

  def unique_trns
    errors.add(:csv_file, 'CSV file contains duplicate TRNs') unless has_unique_trns?
  end

  # @return [Boolean] against file on disk
  def has_valid_csv_headings?
    from_csv.headers.sort.eql?(csv_headings.keys.sort.map(&:to_s))
  end

  # @return [Boolean] against file on disk
  def has_unique_trns?
    rows.map(&:trn).uniq.count.eql?(rows.count)
  end
end
