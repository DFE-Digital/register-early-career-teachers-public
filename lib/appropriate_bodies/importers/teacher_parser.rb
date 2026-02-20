require "csv"

module AppropriateBodies::Importers
  #
  # Process CSV data or a CSV filename
  # - exclude persisted teacher record
  # - exclude active TRS induction statuses
  #
  class TeacherParser
    PARSER_ERROR_LOG = "tmp/dqt_teacher_parser.log"
    HEADERS = %w[trn first_name last_name extension_length extension_length_unit induction_status].freeze

    Row = Struct.new(:trn, :first_name, :last_name, :induction_status, :extension_terms, keyword_init: true) do
      # @return [Hash]
      def to_h
        {
          trn:,
          trs_first_name: first_name_with_fallback,
          trs_last_name: last_name_with_fallback,
          trs_induction_status: induction_status, # new value we expect not to change on the next sync
        }
      end

      # @return [Hash]
      def extension_h
        { trn:, extension_terms: }
      end

      # @return [String]
      def first_name_with_fallback
        first_name || "Unknown"
      end

      # @return [String]
      def last_name_with_fallback
        last_name || "Unknown"
      end
    end

    attr_accessor :logger,
                  :csv_rows,
                  :trns_already_persisted,
                  :unwanted_statuses

    def initialize(data_csv:, trns_with_induction_periods:, logger: nil)
      @trns_already_persisted = Teacher.all.pluck(:trn).to_set
      @unwanted_statuses = %w[RequiredToComplete InProgress].to_set

      sorted_trns_with_induction_periods = trns_with_induction_periods.compact.sort
      file = data_csv.to_s.ends_with?("teachers.csv") ? File.readlines(data_csv) : data_csv.scan(/.*\n/)
      file.delete_at(0)
      sorted_lines = file.sort
      wanted_lines = []
      seek = sorted_trns_with_induction_periods.shift

      sorted_lines.each do |line|
        next unless line.start_with?(seek)

        wanted_lines << line
        break if sorted_trns_with_induction_periods.empty?

        seek = sorted_trns_with_induction_periods.shift
      end

      @csv_rows = CSV.parse(wanted_lines.join, headers: HEADERS)

      File.open(PARSER_ERROR_LOG, "w") { |f| f.truncate(0) }
      @logger = logger || Logger.new(PARSER_ERROR_LOG, File::CREAT)
    end

    # @return [Array<Struct>]
    def rows
      @rows ||= filtered_rows.map { |row| Row.new(**build(row)) }
    end

  private

    # @return [Array<CSV::Row>]
    def filtered_rows
      csv_rows.reject { |row| exclude_teacher?(trn: row["trn"], status: row["induction_status"]) }
    end

    # @param trn [String]
    # @param status [String]
    # @return [Boolean]
    def exclude_teacher?(trn:, status:)
      return true if trn.nil?
      return true if status.in?(unwanted_statuses)

      if trn.in?(trns_already_persisted)
        logger.error "#{trn} teacher already in the database"
        return true
      end

      false
    end

    # @param row [CSV::Row]
    # @return [Hash]
    def build(row)
      {
        trn: row["trn"],
        first_name: row["first_name"]&.strip,
        last_name: row["last_name"]&.strip,
        induction_status: row["induction_status"],
        extension_terms: convert_extension(row)
      }
    end

    # @param row [CSV::Row]
    # @return [Integer, nil]
    def convert_extension(row)
      unit = row["extension_length_unit"]
      value = row["extension_length"].to_i

      return if unit.blank? || value.zero?

      converted_value =
        case unit
        when "Years" then value * 3.0
        when "Terms" then value
        when "Months" then value / 3.0
        when "Weeks" then value / 13.0
        when "Days" then value / 65.0
        end

      converted_value.round(1)
    end
  end
end
