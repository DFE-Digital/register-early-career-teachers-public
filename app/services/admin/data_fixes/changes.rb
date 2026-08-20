module Admin::DataFixes
  class Changes
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations

    attribute :parsed_rows

    validate :all_results_successful

    def process
      return false unless valid?

      results.map(&:saved_change)
    end

  private

    def results = @results ||= parsed_rows.map { process_row(it) }

    def process_row(row)
      Processor.new.process!(data_change: row.with_indifferent_access)
    end

    def all_results_successful
      results.each.with_index do |result, index|
        errors.add(:base, "Row #{index + 1}: #{result.error}") unless result.success?
      end
    end
  end
end
