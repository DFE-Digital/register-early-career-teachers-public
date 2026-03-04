require "csv"

module AppropriateBodies::Importers
  #
  # Process CSV data or a CSV filename
  # - exclude persisted teacher record
  # - exclude active TRS induction statuses
  #
  class TeacherParser
    PARSER_ERROR_LOG = "tmp/dqt_teacher_parser.log"
    UNWANTED_STATUSES = %w[RequiredToComplete InProgress].freeze
    HEADERS = %w[trn first_name last_name extension_length extension_length_unit induction_status].freeze

    # UNWANTED_TEACHER_IDS = [76_075, 93_314].freeze # move to induction parser

    Row = Struct.new(:trn, :first_name, :last_name, :induction_status, :extension_terms, keyword_init: true) do
      def to_h
        {
          trn:,
          trs_first_name: first_name_with_fallback,
          trs_last_name: last_name_with_fallback,
          trs_induction_status: induction_status, # new value we expect not to change on the next sync
        }
      end

      def extension_h
        { trn:, extension_terms: }
      end

      def first_name_with_fallback
        first_name || "Unknown"
      end

      def last_name_with_fallback
        last_name || "Unknown"
      end
    end

    attr_accessor :logger,
                  :csv,
                  :trns_already_persisted

    def initialize(data_csv:, trns_with_induction_periods:, logger: nil)
      @trns_already_persisted = Teacher.all.pluck(:trn)

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

      @csv = CSV.parse(wanted_lines.join, headers: HEADERS)

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
      csv.reject do |row|
        case
        when row["induction_status"].in?(UNWANTED_STATUSES)
          true
        when row["trn"].nil?
          true
        when row["trn"].in?(trns_already_persisted)
          logger.error "#{row['trn']} teacher already in the database"
          true
        else
          false
        end
      end
    end

    def build(row)
      {
        trn: row["trn"],
        first_name: row["first_name"]&.strip,
        last_name: row["last_name"]&.strip,
        induction_status: row["induction_status"],
        extension_terms: convert_extension(row)
      }
    end

    def convert_extension(row)
      unit = row["extension_length_unit"]
      value = row["extension_length"].to_i

      return if unit.blank? || value.zero?

      converted_value = case unit
                        when "Years"
                          # there are 3 terms per school year
                          value * 3.0
                        when "Terms"
                          value
                        when "Months"
                          # there are approximately 3 months in a term
                          # (13 weeks in a term; 4.3 weeks in a month; 13 / 4.3 ≈ 3)
                          value / 3.0
                        when "Weeks"
                          # there are usually 13 weeks in a term
                          value / 13.0
                        when "Days"
                          # assuming working days have been counted
                          # (13 weeks in a term; 5 days in a week; 13 * 5 = 65
                          value / 65.0
                        end

      converted_value.round(1)
    end
  end
end
