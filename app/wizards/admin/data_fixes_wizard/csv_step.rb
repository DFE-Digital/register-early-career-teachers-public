module Admin::DataFixesWizard
  class CSVStep < Step
    def self.permitted_params = %i[csv_string]

    attribute :csv_string, :string

    def previous_step = nil
    def next_step = :preview

    def save!
      parsed_rows = inline_csv.parse
      store.parsed_rows = parsed_rows if parsed_rows
    end

    delegate :errors, to: :inline_csv

  private

    def inline_csv
      @inline_csv ||= Admin::DataFixes::InlineCSV.new(csv_string:)
    end
  end
end
