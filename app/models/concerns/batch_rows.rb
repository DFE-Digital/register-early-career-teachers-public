module BatchRows
  extend ActiveSupport::Concern

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

  # @return [Class] A class that represents a row in the CSV file
  # @param columns [Array<Symbol>] Array of CSV column headings
  def self.build_row_class(columns)
    Data.define(*columns) do
      include Enumerable

      # @return [Boolean] 7 digits
      def invalid_trn?
        trn !~ /\A\d{7}\z/
      end

      # @return [Boolean] only "error" cell can be blank
      def blank_cell?
        members[0..-2].any? { |key| public_send(key).blank? }
      end

      # @return [Boolean] pass, fail, release
      def invalid_outcome?
        objective !~ /\Apass|fail|release\z/i
      end

      # @return [Boolean] upto one decimal place
      def invalid_terms?
        number_of_terms !~ /\A\d+(\.\d{1})?\z/
      end

      # @return [Boolean] formatted as YYYY-MM-DD
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

  ActionRow = build_row_class(ACTION_CSV_HEADINGS.keys)
  ClaimRow = build_row_class(CLAIM_CSV_HEADINGS.keys)

  # @return [Hash]
  def row_headings
    return ACTION_CSV_HEADINGS if action?

    CLAIM_CSV_HEADINGS if claim?
  end

  # @return [Array<String>]
  def column_headers
    row_headings.keys.map(&:to_s)
  end

  # @return [Enumerator::Lazy<ClaimRow, ActionRow>] Struct-like without headers
  def rows
    data.each.lazy.map { |row| row_class.new(**row.symbolize_keys) }
  end

private

  # @return [ActionRow, ClaimRow]
  def row_class
    return ActionRow if action?

    ClaimRow if claim?
  end
end
