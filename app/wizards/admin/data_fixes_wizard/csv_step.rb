module Admin::DataFixesWizard
  class CSVStep < Step
    def self.permitted_params = %i[csv_string]

    attribute :csv_string, :string

    def previous_step = nil
    def next_step = :preview

    def save!
      parsed_rows = inline_csv.parse
      store.parsed_rows = parsed_rows.presence || nil
    end

    delegate :errors, to: :inline_csv

  private

    def inline_csv
      @inline_csv ||= Admin::DataFixes::InlineCSV.new(csv_string:)
    end

    def pre_populate_attributes
      self.csv_string = generate_csv_from(store.parsed_rows) if store.parsed_rows
    end

    def generate_csv_from(parsed_rows)
      CSV.generate do |csv|
        csv << parsed_rows.first.keys
        parsed_rows.each do |row|
          csv << row.values
        end
      end
    end
  end
end
