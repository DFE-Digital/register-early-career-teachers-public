module Admin::DataFixesWizard::Operations
  class ParseCSV
    HEADER_ROW = %w[object_type object_id action attributes].freeze

    def initialize(repository:, step:)
      @repository = repository
      @step = step
    end

    def execute
      if parsed_csv.headers != HEADER_ROW
        step.errors.add(:csv_string, "CSV has invalid headers")
        { success: false, errors: step.errors }
      else
        step.parsed_rows = parsed_csv.map(&:to_hash)
        { success: true }
      end
    rescue CSV::MalformedCSVError => _e
      step.errors.add(:csv_string, "CSV is malformed")
      { success: false, errors: step.errors }
    end

  private

    attr_reader :repository, :step

    def parsed_csv = @parsed_csv ||= CSV.parse(step.csv_string, headers: true)
  end
end
