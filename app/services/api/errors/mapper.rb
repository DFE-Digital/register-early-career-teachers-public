module API
  module Errors
    class Mapper
      class MappingsFileNotFoundError < RuntimeError; end

      YAML_FILE_PATH = "config/api_error_mappings.yml"

      attr_reader :mappings_file, :mappings

      def initialize
        @mappings = load_mappings!
      end

      def map_error(title:, detail:)
        { title:, detail: }.transform_values { replace(it) }
      end

    private

      def load_mappings!
        raise MappingsFileNotFoundError, "Mappings file not found: #{YAML_FILE_PATH}" unless File.exist?(YAML_FILE_PATH)

        YAML.load_file(YAML_FILE_PATH)&.sort_by(&:length)&.reverse || {}
      end

      def replace(text)
        mappings.reduce(text.to_s) { |t, (from, to)| t.gsub(from.to_s, to.to_s) }
      end
    end
  end
end
