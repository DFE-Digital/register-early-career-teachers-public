module Admin::DataFixes
  class InlineCSV
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations

    HEADER_ROW = %w[object_type object_id action attributes].freeze

    attribute :csv_string, :string

    validates :csv_string, presence: { message: "CSV can’t be blank" }
    validate :expected_headers

    def parse
      return false unless valid?

      parsed_csv.map(&:to_hash)
    rescue CSV::MalformedCSVError => _e
      errors.add(:csv_string, "CSV is malformed")
      false
    end

  private

    def parsed_csv = @parsed_csv ||= CSV.parse(csv_string, headers: true)

    def expected_headers
      if parsed_csv.headers != HEADER_ROW
        errors.add(:csv_string, "CSV has invalid headers")
      end
    end
  end
end
