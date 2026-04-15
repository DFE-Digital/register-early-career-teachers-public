module Mappers
  class AppropriateBodyMapper
    attr_accessor :mapping_data, :indexed_by_ecf1_id

    def initialize(yaml_file = Rails.root.join("app/migration/mappers/appropriate_body_mapping_data.yaml"))
      @mapping_data = YAML.load_file(yaml_file, symbolize_names: true)
      @indexed_by_ecf1_id = mapping_data.index_by { it[:ecf1_id] }
    end

    def get_ecf2_id(ecf1_id)
      match = indexed_by_ecf1_id[ecf1_id]

      match[:ecf2_id]
    end
  end
end
