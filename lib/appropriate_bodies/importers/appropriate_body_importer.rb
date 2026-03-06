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

    attr_accessor :logger # or just reader

    attr_reader :data_csv,
                :dfe_sign_in_mapping_csv,
                :existing_dqt_uuids

    def initialize(data_csv:, dfe_sign_in_mapping_csv:, logger: nil)
      @data_csv = data_csv
      @dfe_sign_in_mapping_csv = dfe_sign_in_mapping_csv
      @existing_dqt_uuids = AppropriateBodyPeriod.pluck(:dqt_id)

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

    def genuine_data?
      data_csv.to_s.ends_with?("appropriatebody.csv")
    end

    def genuine_map?
      dfe_sign_in_mapping_csv.to_s.ends_with?("dfe-sign-in-mappings.csv")
    end

    def csv_rows
      genuine_data? ? CSV.read(data_csv, headers: true) : CSV.parse(data_csv, headers: true)
    end

    def dfe_sign_in_mapping
      genuine_map? ? CSV.read(dfe_sign_in_mapping_csv, headers: true) : CSV.parse(dfe_sign_in_mapping_csv, headers: true)
    end

    # @return [Array<CSV::Row>]
    def filtered_rows
      csv_rows.reject do |row|
        case
        when row["id"].in?(existing_dqt_uuids)
          logger.error "#{row['name']} AB already in the database"
          true
        when row["id"].in?(OFFSHORE_DQT_UUIDS)
          logger.error "#{row['name']} is offshore"
          true
        else
          false
        end
      end
    end

    def build(row)
      {
        name: fetch_name(row),
        dfe_sign_in_organisation_id: fetch_dfe_sign_in_organisation_id(row),
        dqt_id: row["id"],
      }
    end

    def fetch_name(row)
      dqt_uuid_to_ab.dig(row["id"], "appropriate_body_name") || row["name"]
    end

    def fetch_dfe_sign_in_organisation_id(row)
      dqt_uuid_to_ab.dig(row["id"], "dfe_sign_in_organisation_id")
    end

    def dqt_uuid_to_ab
      @dqt_uuid_to_ab ||= dfe_sign_in_mapping.map(&:to_h).index_by { |r| r["dqt_id"] }
    end
  end
end
