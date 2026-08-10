module Admin::DataFixes
  class InlineCSV
    class InvalidHeaderError < ArgumentError; end

    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations

    HEADER_ROW = %w[object_type object_id action attributes].freeze
    Row = Data.define(*HEADER_ROW)

    attribute :csv_string, :string

    validates :csv_string, presence: true
    validate :expected_headers

    def parse
      return false unless valid?

      parsed_csv.map { Row.new(**it) }
    rescue CSV::MalformedCSVError => _e
      errors.add(:csv_string, "is malformed")
      false
    end

  private

    def parsed_csv = @parsed_csv ||= CSV.parse(csv_string, headers: true)

    def expected_headers
      if parsed_csv.headers != HEADER_ROW
        errors.add(:csv_string, "has invalid headers")
      end
    end
  end
end
