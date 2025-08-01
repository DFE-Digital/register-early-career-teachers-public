module BatchRows
  extend ActiveSupport::Concern

  CLAIM_CSV_HEADINGS = {
    trn: 'TRN',
    date_of_birth: 'Date of birth',
    training_programme: 'Induction programme',
    started_on: 'Induction period start date',
    error: 'Error message',
  }.freeze

  ACTION_CSV_HEADINGS = {
    trn: 'TRN',
    date_of_birth: 'Date of birth',
    finished_on: 'Induction period end date',
    number_of_terms: 'Number of terms',
    outcome: 'Outcome',
    error: 'Error message',
  }.freeze

  # @return [Class] A class that represents a row in the CSV file
  # @param columns [Array<Symbol>] Array of CSV column headings
  def self.build_row_class(columns)
    Data.define(*columns) do
      include Enumerable

      # @return [Boolean] 7 digits only
      def invalid_trn?
        trn.to_s.strip !~ ::Teacher::TRN_FORMAT
      end

      # @return [Boolean] only "error" cell can be blank
      def blank_cell?
        members[0..-2].any? { |key| public_send(key).blank? }
      end

      # @return [Boolean] formatted as YYYY-MM-DD
      def invalid_date?
        members.grep(/date_of_birth|started_on|finished_on/).any? do |key|
          !Date.iso8601(public_send(key))
        rescue Date::Error
          true
        end
      end

      # @return [Boolean] induction dates must be in the past
      def future_dates?
        members.grep(/started_on|finished_on/).any? do |key|
          Date.parse(public_send(key).to_s).future?
        rescue Date::Error
          true
        end
      end

      # @return [Boolean] not between 18-99
      def invalid_age?
        !(Time.zone.today.year - Date.parse(date_of_birth.to_s).year).between?(18, 99)
      rescue Date::Error
        true
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
          public_send(key).to_s.dup.force_encoding("UTF-8")
        end
      end

      # @see Schools::Validation::TeacherReferenceNumber
      # @return [String] Ensure a sparse record can be created even if it changes the TRN
      def sanitised_trn
        trn.to_s.gsub(/[^\d]/, "")[0, 7]
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
    data.each.lazy.map do |row|
      row_class.new(**row_headings.transform_values { nil }, **row.symbolize_keys)
    end
  end

private

  # @return [ActionRow, ClaimRow]
  def row_class
    return ActionRow if action?

    ClaimRow if claim?
  end
end
