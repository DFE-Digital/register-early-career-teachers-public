require 'csv'

module AppropriateBodies::Importers
  class AppropriateBodyImporter
    IMPORT_ERROR_LOG = 'tmp/appropriate_body_import.log'.freeze

    Row = Struct.new(:legacy_id, :name, :dfe_sign_in_organisation_id, :local_authority_code, :establishment_number) do
      def to_h
        { name:, legacy_id:, establishment_number:, local_authority_code:, dfe_sign_in_organisation_id: }
      end
    end

    def initialize(filename, wanted_legacy_ids, dfe_sign_in_mapping_filename, csv: nil, dfe_sign_in_mapping_csv: nil)
      @csv = csv || CSV.read(filename, headers: true)
      @wanted_legacy_ids = wanted_legacy_ids

      @mapping_csv = dfe_sign_in_mapping_csv || CSV.read(dfe_sign_in_mapping_filename, headers: true)

      File.open(IMPORT_ERROR_LOG, 'w') { |f| f.truncate(0) }
      @import_error_log = Logger.new(IMPORT_ERROR_LOG, File::CREAT)
    end

    def rows
      @csv.map { |row|
        next unless row['id'].in?(@wanted_legacy_ids)

        Row.new(**build(row))
      }.compact
    end

  private

    def build(row)
      # id                                  , name                 , dfe_sign_in_organisation_id, local_authority_code, establishment_number
      # 025e61e7-ec32-eb11-a813-000d3a228dfc, Test Appropriate Body,                            , 1000                ,
      # 69748633-ed32-eb11-a813-000d3a228dfc, ETS Test Organisation, 1234                       ,                     ,

      {
        name: select_name(row).strip,
        dfe_sign_in_organisation_id: select_dfe_sign_in_organsation_id(row),
        legacy_id: row['id'],

        **extract_local_authority_code_and_establishment_number(row)
      }
    end

    def select_name(row)
      if mappings_by_legacy_id.key?(row['id'])
        mappings_by_legacy_id[row['id']].fetch('appropriate_body_name')
      else
        row['name']
      end
    end

    def select_dfe_sign_in_organsation_id(row)
      if mappings_by_legacy_id.key?(row['id'])
        mappings_by_legacy_id[row['id']].fetch('dfe_sign_in_organisation_id')
      end
    end

    def mappings_by_legacy_id
      @mappings_by_legacy_id ||= @mapping_csv.map(&:to_h).index_by { |r| r['dqt_id'] }
    end

    def mappings_by_ab_name
      @mappings_by_ab_name ||= @mapping_csv.map(&:to_h).index_by { |r| r['appropriate_body_name'] }
    end

    def extract_local_authority_code_and_establishment_number(row)
      local_authority_code = row['local_authority_code']

      # the local authority code contains a mix of data in various
      # formats, e.g.,: # 51, 052, 101//101, 202, 885/5403
      #
      # 3 numbers is a local authority code (https://www.get-information-schools.service.gov.uk/Guidance/LaNameCodes)
      # e.g., 123
      #
      # 4 numbers is a establishment number
      # e.g., 1234
      #
      # 3 numbers, a slash, followed by 4 numbers is the local authority code combined
      # with with the establishment number to form the establishment ID (aka the 'DfE number')
      # e.g., 123/1234
      params = case local_authority_code
               when %r{\A\d{3}\z}
                 {
                   local_authority_code:
                 }
               when %r{\A\d{4}\z}
                 {
                   establishment_number: local_authority_code
                 }
               when %r{\A\d{3}/\d{4}\z}
                 {
                   local_authority_code: local_authority_code[0..2],
                   establishment_number: local_authority_code[4..8]
                 }
               when %r{\A\d{7}\z}
                 {
                   local_authority_code: local_authority_code[0..2],
                   establishment_number: local_authority_code[3..7]
                 }
               else
                 @import_error_log.error "#########################"
                 @import_error_log.error "Invalid local authority code"
                 @import_error_log.error "Value: #{local_authority_code}"

                 {}
               end

      params.transform_values(&:to_i)
    end
  end
end
