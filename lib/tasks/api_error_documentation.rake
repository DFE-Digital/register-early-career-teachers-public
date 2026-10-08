namespace :api do
  namespace :error_documentation do
    desc "Generate API validation error documentation"
    task :generate, [:output] => :environment do
      output = Rails.root.join("documentation/api-errors.md").to_s
      command = ["bundle", "exec", "rspec", "spec/services/api", "--example", "validations"]
      success = system({ "API_ERROR_DOCUMENTATION_PATH" => output }, *command)

      abort "RSpec failed" unless success

      puts "Generated #{output}"
    end
  end
end
