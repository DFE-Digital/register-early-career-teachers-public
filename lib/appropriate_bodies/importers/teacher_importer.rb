require 'csv'

module AppropriateBodies::Importers
  class TeacherImporter
    IMPORT_ERROR_LOG = 'tmp/teacher_import.log'.freeze

    Row = Struct.new(:trn, :first_name, :last_name, :induction_status) do
      def to_h
        {
          trn:,
          trs_first_name: first_name_with_fallback,
          trs_last_name: last_name_with_fallback,
        }
      end

      def first_name_with_fallback
        first_name || 'Unknown'
      end

      def last_name_with_fallback
        last_name || 'Unknown'
      end
    end

    def initialize(filename, wanted_trns)
      sorted_wanted_trns = wanted_trns.sort

      file = File.readlines(filename)
      file.delete_at(0)
      sorted_lines = file.sort

      wanted_lines = []

      seek = sorted_wanted_trns.shift

      sorted_lines.each do |line|
        next unless line.start_with?(seek)

        wanted_lines << line

        break if sorted_wanted_trns.empty?

        seek = sorted_wanted_trns.shift
      end

      @csv = CSV.parse(wanted_lines.join, headers: %w[trn first_name last_name induction_status])
    end

    def rows
      @rows ||= @csv.map { |row| Row.new(**build(row)) }
    end

  private

    def build(row)
      {
        trn: row['trn'],
        first_name: row['first_name']&.strip,
        last_name: row['last_name']&.strip,
        induction_status: row['induction_status']
        # FIXME: extensions
      }
    end

    # TODO: beware there are plenty of big assumptions in this method,
    #       these need to be discussed with the team
    def convert_extension(row)
      unit = row['extension_length_unit']
      value = row['extension_length'].to_i

      return if unit.blank? || value.zero?

      converted_value = case unit
                        when 'Years'
                          # there are 3 terms per school year
                          value * 3.0
                        when 'Terms'
                          value
                        when 'Months'
                          # there are approximately 3 months in a term
                          # (13 weeks in a term; 4.3 weeks in a month; 13 / 4.3 ≈ 3)
                          value / 3.0
                        when 'Weeks'
                          # there are usually 13 weeks in a term
                          value / 13.0
                        when 'Days'
                          # assuming working days have been counted
                          # (13 weeks in a term; 5 days in a week; 13 * 5 = 65
                          value / 65.0
                        end

      converted_value.round
    end
  end
end
