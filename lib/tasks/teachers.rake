require "csv"

namespace :teachers do
  namespace :import do
    desc "Import Early roll-out mentors from a CSV file"
    task :early_rollout_mentors, [:csv_path] => :environment do |_task, args|
      csv_path = args[:csv_path]
      raise Errno::ENOENT, "CSV file not found: #{csv_path}" unless File.exist?(csv_path)

      Rails.logger.info("Importing Early roll-out mentors from #{csv_path}")

      CSV.foreach(csv_path, headers: false).with_index(1) do |row, row_number|
        trn = row&.first.to_s.strip

        Teachers::ImportEarlyRolloutMentor.new(trn:).call
      rescue StandardError => e
        Rails.logger.error("Row #{row_number}: #{e.message}")
      end
    end
  end
end
