module AppropriateBodies
  # Validate an uploaded CSV file using file size, content type, column headers, row counts and unique TRNs
  # Export an array of hashes which can be saved to PendingInductionSubmissionBatch#data
  class ProcessBatchForm
    MAX_FILE_SIZE = 100.kilobytes
    MAX_ROW_SIZE = 1_000
    MIME_TYPES = %w[text/csv text/comma-separated-values application/csv].freeze

    include ActiveModel::Model
    include ActiveModel::Validations

    # @see [BatchRows::CLAIM_CSV_HEADINGS, BatchRows::ACTION_CSV_HEADINGS]
    attr_accessor :headers,
                  :file_name,
                  :file_size,
                  :file_type,
                  :file_content

    # Attribute validations
    validates :file_name, presence: true
    validates :file_type, presence: true
    validates :file_size, presence: true
    validates :headers, presence: true
    validates :file_content, presence: true

    # File validations
    validate :csv_file
    validate :csv_file_size
    validate :template, if: -> { is_a_csv? }
    validate :row_count, if: -> { is_a_csv? }
    validate :unique_trns, if: -> { is_a_csv? }

    # @param headers [Hash{Symbol => String}]
    # @param csv_file [ActionDispatch::Http::UploadedFile]
    # @return [ProcessBatchForm]
    def self.from_uploaded_file(headers:, csv_file:)
      new(
        headers:,
        file_name: csv_file.original_filename,
        file_size: csv_file.size,
        file_type: csv_file.content_type,
        file_content: csv_file.read
      )
    end

    # @return [Array<Hash{Symbol => String}>]
    def to_a
      rows.map do |row|
        row.to_h.compact.transform_keys { |k| headers.invert[k] }.transform_values(&:strip)
      end
    end

    # @return [Hash{Symbol => String}]
    def metadata
      { file_name:, file_size: file_size.to_s, file_type: }
    end

  private

    def rows
      parse.reject { |row| row['TRN'].blank? }
    end

    # NB: lines can be commented out for easier dev and testing
    def parse
      @parse ||= CSV.parse(file_content, headers: true, skip_lines: /^#/)
    end

    # Validation messages

    def csv_file
      errors.add(:csv_file, 'The selected file must be a CSV') unless is_a_csv?
    end

    def csv_file_size
      errors.add(:csv_file, 'File size must be less than 100KB') if is_too_large?
    end

    def row_count
      errors.add(:csv_file, "The selected file must have fewer than #{MAX_ROW_SIZE} rows") if has_too_many_rows?
      errors.add(:csv_file, 'The selected file is empty') if has_too_few_rows?
    end

    def unique_trns
      errors.add(:csv_file, 'The selected file has duplicate ECTs') unless has_unique_trns?
    end

    def template
      errors.add(:csv_file, 'The selected file must follow the template') unless has_valid_headers?
    end

    # Validation checks

    def is_a_csv?
      MIME_TYPES.include?(file_type) && file_name.match?(/\.csv\z/i)
    end

    def is_too_large?
      file_size > MAX_FILE_SIZE
    end

    def has_too_many_rows?
      rows.count > MAX_ROW_SIZE
    end

    def has_too_few_rows?
      rows.count.zero?
    end

    # The "error" column is optional. Failed rows downloaded as a CSV contain errors
    # and the user need not remove that column before reuploading the corrected data.
    def has_valid_headers?
      template_headers = headers.values.sort
      template_headers_without_errors = template_headers.reject { |v| v.match?(/error/i) }
      parsed_headers = parse.headers.compact.sort
      [template_headers, template_headers_without_errors].to_set.include?(parsed_headers)
    end

    def has_unique_trns?
      trns = rows.map { |row| row['TRN'] }
      trns.uniq.count.eql?(trns.count)
    end
  end
end
