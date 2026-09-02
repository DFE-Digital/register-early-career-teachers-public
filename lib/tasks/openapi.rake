namespace :openapi do
  desc "Generate the OpenAPI specification"
  task generate: :environment do
    system(
      { "GENERATE_OPENAPI" => "1" },
      "bundle",
      "exec",
      "rspec",
      "spec/requests/api/openapi_spec.rb",
      exception: true
    )
  end
end
