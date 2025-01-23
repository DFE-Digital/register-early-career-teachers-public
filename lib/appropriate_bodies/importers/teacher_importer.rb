require 'csv'

module AppropriateBodies::Importers
  class TeacherImporter
    IMPORT_ERROR_LOG = 'tmp/teacher_import.log'.freeze

    Row = Struct.new(:trn, :trs_first_name, :trs_last_name)

    def initialize(filename)
      @csv = CSV.read(filename, headers: true)

      File.open(IMPORT_ERROR_LOG, 'w') { |f| f.truncate(0) }
      @import_error_log = Logger.new(IMPORT_ERROR_LOG, File::CREAT)
    end

    def rows
      @csv.first(5000).map { |row| Row.new(**build(row)) }
    end

    # def import
    #   count = 0
    #
    #   Teacher.transaction do
    #     @csv.each.with_index(1) do |row, i|
    #       Rails.logger.debug("attempting to import row: #{row.to_h}")
    #
    #       next if row.values_at('trn', 'first_name', 'last_name').any?(&:blank?)
    #
    #       begin
    #         Teacher.create!(**(build(row))).tap do |teacher|
    #           if (induction_extension_terms = convert_extension(row)) && induction_extension_terms.positive?
    #             Rails.logger.warn("Importing extension: #{induction_extension_terms}")
    #             teacher.induction_extensions.create!(number_of_terms: induction_extension_terms)
    #           end
    #         end
    #       rescue ActiveRecord::RecordInvalid => e
    #         @import_error_log.error "#########################"
    #         @import_error_log.error "Failed to import Teacher"
    #         @import_error_log.error "Row number: #{i}"
    #         @import_error_log.error "Message: #{e.message}"
    #         @import_error_log.error "Row data: #{row}"
    #       end
    #
    #       count += 1
    #     end
    #   end
    #
    #   [count, @csv.count]
    # end

  private

    def build(row)
      {
        trn: row['trn'],
        trs_first_name: row['first_name'].strip,
        trs_last_name: row['last_name']&.strip,
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
