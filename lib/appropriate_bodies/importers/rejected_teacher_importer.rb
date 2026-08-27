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
        service_trns = Teacher.pluck(:trn).to_set
        target_trns = rows_by_trn.keys.reject { |trn| service_trns.include?(trn) }
        skipped_trns = rows_by_trn.keys - target_trns
        teacher_data = target_trns.map { |trn| { trn: } }
        inserted_teachers = Teacher.insert_all!(teacher_data, returning: %i[id trn])
        inserted_trns = inserted_teachers.to_h { |row| [row["trn"], row["id"]] }

        event_data = target_trns.map do |trn|
          teacher_id = inserted_trns.fetch(trn)

          reason = rows_by_trn.fetch(trn).map { |row| row["reason"] }.compact.uniq.first

          originals = rows_by_trn.fetch(trn).map do |row|
            {
              legacy_appropriate_body_id: row["dqt_id_discarded"],
              started_on: row["started_on_discarded"],
              finished_on: row["finished_on_discarded"],
            }
          end
          event_params(teacher_id:, reason:, originals:)
        end

        events = Event.insert_all!(event_data)

        logger.info("Created #{target_trns.size} teachers with #{events.count} rejection events (#{skipped_trns.count} skipped)")
      end
    end

  private

    # @return [Hash]
    # @param teacher_id [Integer]
    # @param reason [String]
    # @param originals [Array<Hash>]
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
