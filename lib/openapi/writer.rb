module OpenAPI
  class Writer
    DEFAULT_PATH = Rails.root.join("public/api/docs/openapi.yaml")

    def self.write(path: DEFAULT_PATH)
      FileUtils.mkdir_p(path.dirname)

      File.write(
        path,
        OpenAPI::Document.build.to_yaml(line_width: -1)
      )

      path
    end
  end
end
