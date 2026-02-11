module Migration
  class FailedCombinationsExporter
    CACHE_KEY = "failed-combinations-data"

    attr_reader :query

    FailedCombinationRow = Struct.new(
      :participant_profile_id,
      :participant_profile_type,
      :school_urn,
      :cohort_year,
      :lead_provider_name,
      :delivery_partner_name,
      :induction_record_id,
      :induction_record_created_at,
      :induction_record_updated_at,
      :induction_record_start_date,
      :induction_record_end_date,
      :training_programme,
      :induction_status,
      :training_status,
      :mentor_participant_profile_id,
      :schedule_name,
      :schedule_cohort_year,
      :failure_message,
      keyword_init: true
    )

    def initialize
      @query = DataMigrationFailedCombination.order(:api_id, :profile_type)
    end

    def generate_and_cache_csv
      Rails.cache.fetch(CACHE_KEY, expires_in: 1.minute) do
        generate_csv
      end
    end

    def generate_csv
      CSV.generate(headers: csv_headers, write_headers: true) do |csv|
        query.find_each(batch_size: 2_000) do |failed_combination|
          csv << row(failed_combination)
        end
      end
    end

  private

    def csv_headers
      %w[
        participant_profile_id
        participant_profile_type
        school_urn
        cohort_year
        lead_provider_name
        delivery_partner_name
        induction_record_id
        induction_record_created_at
        induction_record_updated_at
        induction_record_start_date
        induction_record_end_date
        training_programme
        induction_status
        training_status
        mentor_participant_profile_id
        schedule_name
        schedule_cohort_year
        failure_message
      ].freeze
    end

    def row(failed_combination)
      FailedCombinationRow.new(
        participant_profile_id: failed_combination.profile_id,
        participant_profile_type: failed_combination.profile_type,
        school_urn: failed_combination.school_urn,
        cohort_year: failed_combination.cohort_year,
        lead_provider_name: failed_combination.lead_provider_name,
        delivery_partner_name: failed_combination.delivery_partner_name,
        induction_record_id: failed_combination.induction_record_id,
        induction_record_created_at: failed_combination.created_at,
        induction_record_updated_at: failed_combination.updated_at,
        induction_record_start_date: failed_combination.start_date.to_date,
        induction_record_end_date: failed_combination.end_date&.to_date,
        training_programme: failed_combination.training_programme,
        induction_status: failed_combination.induction_status,
        training_status: failed_combination.training_status,
        mentor_participant_profile_id: failed_combination.mentor_profile_id,
        schedule_name: failed_combination.schedule_name,
        schedule_cohort_year: failed_combination.schedule_cohort_year,
        failure_message: failed_combination.failure_message
      )
    end
  end
end
