require "csv"

module AppropriateBodies::Importers
  # Persist teachers who were excluded from the DQT import due to invalid induction data
  class RejectedTeacherImporter
    attr_reader :logger

    def initialize(data_csv:, logger: nil)
      @data_csv = data_csv
      @logger = logger || Logger.new($stdout)
    end

    def import!
      ActiveRecord::Base.transaction do
        rows_by_trn = csv_rows.group_by { |row| row["trn"] }
        rejected_trns = rows_by_trn.keys

        # identify missing records
        existing_trns = Teacher.where(trn: rejected_trns).pluck(:trn)
        missing_trns = rejected_trns - existing_trns

        # fail fast if already imported
        raise "Import found no missing teachers" if missing_trns.none?

        # Insert any teachers who are missing
        missing_teacher_data = missing_trns.map { |trn| { trn: } }
        teachers = Teacher.insert_all!(missing_teacher_data)

        # fetch all rejected teacher data
        rejected_ids = Teacher.where(trn: rejected_trns).pluck(:trn, :id).to_h

        # build event data from CSV which uses as single consistent reason for any rejected induction rows
        event_data = rejected_trns.map do |trn|
          teacher_id = rejected_ids.fetch(trn)
          teacher_invalid_rows = rows_by_trn.fetch(trn)

          reason = teacher_invalid_rows.map { |row| row["reason"] }.compact.uniq.first

          originals = teacher_invalid_rows.map do |row|
            {
              legacy_appropriate_body_id: row["dqt_id_discarded"],
              started_on: extract_date(row["started_on_discarded"]),
              finished_on: extract_date(row["finished_on_discarded"])
            }
          end
          event_params(teacher_id:, reason:, originals:)
        end

        events = Event.insert_all!(event_data)

        logger.info("Created #{teachers.count} missing teachers and added #{events.count} rejection events for #{rejected_trns.size} TRNs")
      end
    end

  private

    # @param date [String]
    # @return [Date, nil]
    def extract_date(date)
      return if date.blank?

      Date.strptime(date, "%d/%m/%Y")
    end

    # @param teacher_id [Integer]
    # @param reason [String]
    # @param originals [Array<Hash>]
    # @return [Hash]
    def event_params(teacher_id:, reason:, originals:)
      {
        author_type: :system,
        event_type: :import_from_dqt,
        heading: "DQT data import rejected",
        body: reason,
        teacher_id:,
        happened_at: Time.zone.now,
        metadata: { originals: }
      }
    end

    # @return [CSV::Table]
    def csv_rows
      File.exist?(@data_csv) ? CSV.read(@data_csv, headers: true) : CSV.parse(@data_csv, headers: true)
    end
  end
end
