module AppropriateBodies
  # Validate an uploaded CSV file using file size, content type, column headers, row counts and unique TRNs
  # Export an array of hashes which can be saved to PendingInductionSubmissionBatch#data
  class ProcessBatchForm
    MAX_FILE_SIZE = 1.megabyte
    MAX_ROW_SIZE = 5
    MIME_TYPES = %w[text/csv text/comma-separated-values application/csv].freeze

    include ActiveModel::Model
    include ActiveModel::Validations

    # @see [BatchRows::CLAIM_CSV_HEADINGS, BatchRows::ACTION_CSV_HEADINGS]
    attr_accessor :file_content, :content_type, :headers, :file_size

    validates :file_content, presence: true
    validates :headers, presence: true

    # validations
    validate :csv_mime_type
    validate :csv_file_size
    validate :wrong_headers
    validate :row_count
    validate :unique_trns

    # @param headers [Hash{Symbol => String}]
    # @param csv_file [ActionDispatch::Http::UploadedFile]
    # @return [ProcessBatchForm]
    def self.from_uploaded_file(headers:, csv_file:)
      new(
        headers:,
        file_size: csv_file.size,
        content_type: csv_file.content_type,
        file_content: csv_file.read
      )
    end

    # @return [Array<Hash{Symbol => String}>] replace CSV headers with symbols
    def to_a
      parse.map do |row|
        row.to_h.transform_keys { |k| headers.invert[k] }
      end
    end

  private

    def parse
      @parse ||= CSV.parse(file_content, headers: true, skip_lines: /^#/)
    end

    # Validation messages

    def csv_mime_type
      errors.add(:csv_file, 'The selected file must be a CSV') unless is_a_csv?
    end

    def csv_file_size
      errors.add(:csv_file, 'File size must be less than 1MB') if is_too_large?
    end

    def row_count
      errors.add(:csv_file, 'The selected file must have fewer than 1000 rows') if has_too_many_rows?
      errors.add(:csv_file, 'The selected file is empty') if has_too_few_rows?
    end

    def unique_trns
      errors.add(:csv_file, 'The selected file has duplicate ECTs') unless has_unique_trns?
    end

    def wrong_headers
      errors.add(:csv_file, 'The selected file must follow the template') unless has_valid_headers?
    end

    # Validation checks

    def is_a_csv?
      MIME_TYPES.include?(content_type)
    end

    def is_too_large?
      file_size > MAX_FILE_SIZE
    end

    def has_too_many_rows?
      parse.count > MAX_ROW_SIZE
    end

    def has_too_few_rows?
      parse.count.zero?
    end

    def has_valid_headers?
      parse.headers.sort.eql?(headers.values.sort)
    end

    def has_unique_trns?
      parse.map { |row| row['TRN'] }.uniq.count.eql?(parse.count)
    end
  end
end
