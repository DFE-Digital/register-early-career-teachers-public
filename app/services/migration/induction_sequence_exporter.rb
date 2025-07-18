# frozen_string_literal: true

require "csv"

module Migration
  # Exports induction sequence analysis results to CSV format
  class InductionSequenceExporter
    DEFAULT_FILE_NAME = 'induction_sequences_analysis'

    def initialize(results)
      @results = results
    end

    def export_to_csv(filename: nil)
      file_path = prepare_file_path(filename)

      Rails.logger.info("InductionSequenceExporter: Exporting analysis to CSV: #{file_path}")

      data = @results.flat_map do |result|
        result[:provider_periods].map { |period| build_csv_row(result, period) }
      end

      CSV.open(file_path, "w", headers: data.first.keys, write_headers: true) do |csv|
        data.each { |row| csv << row }
      end

      Rails.logger.info("InductionSequenceExporter: Export completed: #{file_path}")
      file_path.to_s
    end

  private

    def prepare_file_path(filename)
      return default_file_path if filename.blank?

      filename
    end

    def default_file_path
      timestamp = Time.current.strftime('%Y%m%d%H%M%S')

      "/tmp/#{DEFAULT_FILE_NAME}_#{timestamp}.csv"
    end

    def build_csv_row(result, period)
      {
        "Participant ID" => result[:participant_id],
        "Participant Type" => result[:participant_type],
        "Lead Provider" => result[:lead_provider_name],
        "Total Records" => result[:total_record_count],
        "NULL End Date Records" => result[:null_end_date_count],
        "Total Days with Provider" => result[:total_days],
        "Schools" => result[:schools].join(";"),
        "Programme Types" => result[:programme_types].join(";"),
        "Induction Record ID" => period[:record_id],
        "Created At" => period[:created_at],
        "Start Date" => period[:start_date],
        "End Date" => period[:end_date],
        "Explicit End Date" => period[:explicit_end_date] ? "Yes" : "No",
        "Next Induction Record ID" => period[:next_record_id],
        "Duration Days" => period[:duration_days],
        "Period Status" => period[:status],
        "School" => period[:school],
        "School URN" => period[:school_urn],
        "Mentor Profile ID" => period[:mentor_profile_id],
        "Induction Programme Type" => period[:programme],
        "Core Induction Programme" => period[:core_induction_programme],
        "Induction Programme ID" => period[:programme_id],
        "Partnership ID" => period[:partnership_id],
        "Delivery Partner" => period[:delivery_partner],
        "Induction Status" => period[:induction_status],
        "Training Status" => period[:training_status]
      }
    end
  end
end
