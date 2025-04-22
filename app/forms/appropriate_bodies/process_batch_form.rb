module AppropriateBodies
  # validates a csv file, using column headers, file size, row count, and content type
  class ProcessBatchForm
    MAX_FILE_SIZE = 1.megabyte
    MAX_ROW_SIZE = 5
    MIME_TYPES = %w[text/csv text/comma-separated-values application/csv].freeze

    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :file_content, :content_type, :headers, :file_size

    validates :file_content, presence: true
    validates :headers, presence: true

    # validations
    validate :csv_mime_type
    validate :csv_file_size
    validate :row_count
    validate :unique_trns
    validate :wrong_headers

    # @param headers [Array<String>]
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

    # @return [Array<Hash>]
    def to_a
      parse.map(&:to_h)
    end

  private

    def parse
      @parse ||= CSV.parse(file_content, headers: true, skip_lines: /^#/)
    end

    # validation messages

    def csv_mime_type
      errors.add(:csv_file, 'File type must be a CSV') unless is_a_csv?
    end

    def csv_file_size
      errors.add(:csv_file, 'File size must be less than 1MB') if is_too_large?
    end

    def row_count
      errors.add(:csv_file, 'CSV file contains too many rows') if has_too_many_rows?
    end

    def unique_trns
      errors.add(:csv_file, 'CSV file contains duplicate TRNs') unless has_unique_trns?
    end

    def wrong_headers
      errors.add(:csv_file, 'CSV file contains unsupported columns') unless has_valid_headers?
    end

    # validation checks

    def is_a_csv?
      MIME_TYPES.include?(content_type)
    end

    def is_too_large?
      file_size > MAX_FILE_SIZE
    end

    def has_too_many_rows?
      parse.count > MAX_ROW_SIZE
    end

    def has_valid_headers?
      parse.headers.sort.eql?(headers.sort)
    end

    def has_unique_trns?
      parse.map { |row| row['trn'] }.uniq.count.eql?(parse.count)
    end
  end
end
