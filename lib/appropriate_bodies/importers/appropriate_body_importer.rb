require "csv"

module AppropriateBodies::Importers
  class AppropriateBodyImporter
    IMPORT_ERROR_LOG = "tmp/appropriate_body_period_import.log"

    Row = Struct.new(:dqt_id, :name, :dfe_sign_in_organisation_id, :local_authority_code, :establishment_number) do
      def to_h
        { name:, dqt_id:, dfe_sign_in_organisation_id: }
      end
    end

    attr_accessor :logger

    def initialize(filename, wanted_legacy_ids, dfe_sign_in_mapping_filename, csv: nil, dfe_sign_in_mapping_csv: nil, logger: nil)
      @csv = csv || CSV.read(filename, headers: true)
      @wanted_legacy_ids = wanted_legacy_ids

      @mapping_csv = dfe_sign_in_mapping_csv || CSV.read(dfe_sign_in_mapping_filename, headers: true)

      File.open(IMPORT_ERROR_LOG, "w") { |f| f.truncate(0) }
      @logger = logger || Logger.new(IMPORT_ERROR_LOG, File::CREAT)
    end

    def rows
      @csv.map { |row|
        next unless row["id"].in?(@wanted_legacy_ids)

        Row.new(**build(row))
      }.compact
    end

  private

    # id                                  , name                 , dfe_sign_in_organisation_id, local_authority_code, establishment_number
    # 025e61e7-ec32-eb11-a813-000d3a228dfc, Test Appropriate Body,                            , 1000                ,
    # 69748633-ed32-eb11-a813-000d3a228dfc, ETS Test Organisation, 1234                       ,                     ,
    def build(row)
      {
        name: select_name(row).strip,
        dfe_sign_in_organisation_id: select_dfe_sign_in_organsation_id(row),
        dqt_id: row["id"],
      }
    end

    def select_name(row)
      if mappings_by_legacy_id.key?(row["id"])
        mappings_by_legacy_id[row["id"]].fetch("appropriate_body_name")
      else
        row["name"]
      end
    end

    def select_dfe_sign_in_organsation_id(row)
      if mappings_by_legacy_id.key?(row["id"])
        mappings_by_legacy_id[row["id"]].fetch("dfe_sign_in_organisation_id")
      end
    end

    def mappings_by_legacy_id
      @mappings_by_legacy_id ||= @mapping_csv.map(&:to_h).index_by { |r| r["dqt_id"] }
    end

    def mappings_by_ab_name
      @mappings_by_ab_name ||= @mapping_csv.map(&:to_h).index_by { |r| r["appropriate_body_name"] }
    end
  end
end
