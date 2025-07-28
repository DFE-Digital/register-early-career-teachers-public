# Generates a Mermaid ERD to documentation/domain-model.md
# Excludes models listed in config/mermaid_erd.yml under `exclude`

module MermaidErd
  class Generator
    def initialize(config_path:, output_path:)
      @config_path = config_path
      @output_path = output_path
      @exclusions = begin
        YAML.load_file(config_path).fetch('exclude', [])
      rescue Errno::ENOENT
        raise "Missing config file at #{config_path}"
      rescue Psych::SyntaxError => e
        raise "YAML syntax error in #{config_path}: #{e.message}"
      end
    end

    def generate
      Rails.application.eager_load!
      models = load_models
      lines = ['```mermaid', 'erDiagram']

      models.each do |model|
        next unless model.table_exists?

        sanitized_name = sanitize(model.name)
        lines << "  #{sanitized_name} {"
        model.columns.each { |column| lines << "    #{column.type} #{column.name}" }
        lines << "  }"

        model.reflect_on_all_associations(:belongs_to).each do |assoc|
          to = sanitize(assoc.class_name)
          next if excluded?(assoc.class_name)

          lines << "  #{sanitized_name} }o--|| #{to} : belongs_to"
        end
      end

      lines << '```'
      FileUtils.mkdir_p(@output_path.dirname)
      File.write(@output_path, lines.join("\n"))
    end

  private

    def sanitize(name)
      name.gsub('::', '_')
    end

    def excluded?(model_name)
      @exclusions.any? { |pattern| File.fnmatch(pattern, model_name) }
    end

    def load_models
      ActiveRecord::Base.descendants.reject do |model|
        model.abstract_class? || excluded?(model.name) || model.name.start_with?('HABTM_')
      end
    end
  end
end
