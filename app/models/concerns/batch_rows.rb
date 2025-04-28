module BatchRows
  extend ActiveSupport::Concern

  CLAIM_CSV_HEADINGS = {
    trn: 'TRN',
    date_of_birth: 'Date of birth',
    induction_programme: 'Induction programme',
    started_on: 'Induction start date',
    error: 'Error message',
  }.freeze

  ACTION_CSV_HEADINGS = {
    trn: 'TRN',
    date_of_birth: 'Date of birth',
    finished_on: 'Induction end date',
    number_of_terms: 'Number of terms',
    outcome: 'Outcome',
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

      # @return [Boolean] pass, FAIL, Release (case-insensitive)
      def invalid_outcome?
        outcome !~ /\A(pass|fail|release)\z/i
      end

      # @return [Boolean] 0-16 upto one decimal place
      def invalid_terms?
        number_of_terms !~ /\A\d+(\.\d{1})?\z/ || !number_of_terms.to_f.between?(0, 16)
      end

      # @return [Boolean] formatted as YYYY-MM-DD
      def invalid_date?
        members.grep(/date_of_birth|started_on|finished_on/).any? do |key|
          !Date.iso8601(public_send(key))
        rescue Date::Error
          true
        end
      end

      # @param errors [Array<String>]
      # @return [Array<String>]
      def with_errors(errors)
        row_values = to_a
        row_values.pop
        row_values.push(errors.to_sentence)
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
