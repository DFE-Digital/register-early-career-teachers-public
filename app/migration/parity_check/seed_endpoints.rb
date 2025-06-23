module ParityCheck
  class SeedEndpoints
    include ParityCheck::Configuration

    YAML_FILE_PATH = Rails.root.join("config/parity_check_endpoints.yml").freeze

    def plant!
      ensure_parity_check_enabled!

      clear_endpoints!
      seed_endpoints!
    end

  private

    def clear_endpoints!
      ParityCheck::Endpoint.destroy_all
    end

    def seed_endpoints!
      yaml_file
        .flat_map { |method, paths| paths.map { [method, it] } }
        .map { |method, (path, options)| ParityCheck::Endpoint.create!(method:, path:, options:) }
    end

    def yaml_file
      @yaml_file ||= YAML.load_file(YAML_FILE_PATH)
    end
  end
end
