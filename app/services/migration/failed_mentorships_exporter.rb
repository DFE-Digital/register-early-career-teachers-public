module Migration
  class FailedMentorshipsExporter
    CACHE_KEY = "failed-mentorships-data"

    attr_reader :query

    FailedMentorshipRow = Struct.new(
      :ect_participant_profile_id,
      :mentor_participant_profile_id,
      :started_on,
      :finished_on,
      :ecf_start_induction_record_id,
      :ecf_end_induction_record_id,
      :failure_message,
      keyword_init: true
    )

    def initialize
      @query = DataMigrationFailedMentorship.order(:ect_participant_profile_id, :mentor_participant_profile_id)
    end

    def generate_and_cache_csv
      Rails.cache.fetch(CACHE_KEY, expires_in: 1.minute) do
        generate_csv
      end
    end

    def generate_csv
      CSV.generate(headers: csv_headers, write_headers: true) do |csv|
        query.find_each(batch_size: 2_000) do |failed_mentorship|
          csv << row(failed_mentorship)
        end
      end
    end

  private

    def csv_headers
      %w[
        ect_participant_profile_id
        mentor_participant_profile_id
        started_on
        finished_on
        ecf_start_induction_record_id
        ecf_end_induction_record_id
        failure_message
      ].freeze
    end

    def row(failed_mentorship)
      FailedMentorshipRow.new(
        ect_participant_profile_id: failed_mentorship.ect_participant_profile_id,
        mentor_participant_profile_id: failed_mentorship.mentor_participant_profile_id,
        started_on: failed_mentorship.started_on,
        finished_on: failed_mentorship.finished_on.presence,
        ecf_start_induction_record_id: failed_mentorship.ecf_start_induction_record_id,
        ecf_end_induction_record_id: failed_mentorship.ecf_end_induction_record_id,
        failure_message: failed_mentorship.failure_message
      )
    end
  end
end
