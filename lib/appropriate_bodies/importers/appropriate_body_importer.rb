require "csv"

module AppropriateBodies::Importers
  # Insert all 532 onshore appropriate bodies
  class AppropriateBodyImporter
    IMPORT_ERROR_LOG = "tmp/dqt_appropriate_body_importer.log"

    Row = Struct.new(:dqt_id, :name, :dfe_sign_in_organisation_id, keyword_init: true) do
      def to_h
        { name:, dqt_id:, dfe_sign_in_organisation_id: }
      end
    end

    attr_reader :data_csv,
                :dfe_sign_in_mapping_csv,
                :offshore_dqt_uuids,
                :all_dqt_uuids,
                :logger

    def initialize(data_csv:, dfe_sign_in_mapping_csv:, logger: nil)
      @data_csv = data_csv
      @dfe_sign_in_mapping_csv = dfe_sign_in_mapping_csv

      @offshore_dqt_uuids = OFFSHORE_DQT_UUIDS.to_set
      @all_dqt_uuids = AppropriateBodyPeriod.pluck(:dqt_id).to_set

      File.open(IMPORT_ERROR_LOG, "w") { |f| f.truncate(0) }
      @logger = logger || Logger.new(IMPORT_ERROR_LOG, File::CREAT)
    end

    # @return [Integer] 532
    def import!
      ab_result = AppropriateBodyPeriod.insert_all(rows.map(&:to_h))
      Rails.logger.info("Appropriate body periods inserted: #{ab_result.count}")
      ab_result.count
    end

    # @return [Array<Struct>]
    def rows
      filtered_rows.map { |row| Row.new(**build(row)) }
    end

  private

    # @return [Boolean]
    def genuine_data?
      data_csv.to_s.ends_with?("appropriatebody.csv")
    end

    # @return [Boolean]
    def genuine_map?
      dfe_sign_in_mapping_csv.to_s.ends_with?("dfe-sign-in-mappings.csv")
    end

    # @return [CSV::x]
    def csv_rows
      genuine_data? ? CSV.read(data_csv, headers: true) : CSV.parse(data_csv, headers: true)
    end

    # @return [CSV::x]
    def dfe_sign_in_mapping
      genuine_map? ? CSV.read(dfe_sign_in_mapping_csv, headers: true) : CSV.parse(dfe_sign_in_mapping_csv, headers: true)
    end

    # @return [Array<CSV::Row>]
    def filtered_rows
      csv_rows.reject { |row| exclude_appropriate_body?(uuid: row["id"], name: row["name"]) }
    end

    # @param uuid [String]
    # @param name [String]
    # @return [Boolean]
    def exclude_appropriate_body?(uuid:, name:)
      if uuid.in?(all_dqt_uuids)
        logger.error "#{name} is already in the database"
        return true
      end

      if uuid.in?(offshore_dqt_uuids)
        logger.error "#{name} is offshore"
        return true
      end

      false
    end

    # @param row [CSV::Row]
    # @return [Hash]
    def build(row)
      {
        name: fetch_name(row),
        dfe_sign_in_organisation_id: fetch_dfe_sign_in_organisation_id(row),
        dqt_id: row["id"],
      }
    end

    # @param row [CSV::Row]
    # @return [String]
    def fetch_name(row)
      dqt_uuid_to_ab.dig(row["id"], "appropriate_body_name") || row["name"]
    end

    # @param row [CSV::Row]
    # @return [String]
    def fetch_dfe_sign_in_organisation_id(row)
      dqt_uuid_to_ab.dig(row["id"], "dfe_sign_in_organisation_id")
    end

    # @return [Hash{String => Hash}]
    def dqt_uuid_to_ab
      @dqt_uuid_to_ab ||= dfe_sign_in_mapping.map(&:to_h).index_by { |r| r["dqt_id"] }
    end
  end
end
