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

      CSV.open(file_path, "w", write_headers: true, headers: csv_headers) do |csv|
        @results.each do |result|
          write_result_to_csv(csv, result)
        end
      end

      Rails.logger.info("InductionSequenceExporter: Export completed: #{file_path}")
      file_path.to_s
    end

    def csv_headers
      [
        "Participant ID",
        "Participant Type",
        "Lead Provider",
        "Total Records",
        "NULL End Date Records",
        "Total Days with Provider",
        "Schools",
        "Programme Types",
        "Induction Record ID",
        "Created At",
        "Start Date",
        "End Date",
        "Explicit End Date",
        "Next Induction Record ID",
        "Duration Days",
        "Period Status",
        "School",
        "School URN",
        "Mentor Profile ID",
        "Induction Programme Type",
        "Core Induction Programme",
        "Induction Programme ID",
        "Partnership ID",
        "Delivery Partner",
        "Induction Status",
        "Training Status",
      ]
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

    def write_result_to_csv(csv, result)
      result[:provider_periods].each do |period|
        row_data = build_csv_row(result, period)
        csv << row_data
      end
    end

    def build_csv_row(result, period)
      [
        result[:participant_id],
        result[:participant_type],
        result[:lead_provider_name],
        result[:total_record_count],
        result[:null_end_date_count],
        result[:total_days],
        result[:schools].join(";"),
        result[:programme_types].join(";"),
        period[:record_id],
        period[:created_at],
        period[:start_date],
        period[:end_date],
        period[:explicit_end_date] ? "Yes" : "No",
        period[:next_record_id],
        period[:duration_days],
        period[:status],
        period[:school],
        period[:school_urn],
        period[:mentor_profile_id],
        period[:programme],
        period[:core_induction_programme],
        period[:programme_id],
        period[:partnership_id],
        period[:delivery_partner],
        period[:induction_status],
        period[:training_status],
      ]
    end
  end
end
