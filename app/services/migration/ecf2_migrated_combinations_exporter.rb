module Migration
  class ECF2MigratedCombinationsExporter
    CACHE_KEY = "ecf2-migrated-combinations-data"

    attr_reader :query

    ECF1CombinationRow = Struct.new(
      :participant_profile_type,
      :ecf1_participant_profile_id,
      :school_urn,
      :cohort_year,
      :lead_provider_name,
      :induction_record_id,
      keyword_init: true
    )

    def initialize
      @query = DataMigrationTeacherCombination.order(:api_id)
    end

    def generate_and_cache_csv
      Rails.cache.fetch(CACHE_KEY, expires_in: 1.minute) do
        generate_csv
      end
    end

    def generate_csv
      CSV.generate(headers: csv_headers, write_headers: true) do |csv|
        query.find_each(batch_size: 2_000) do |teacher_combination|
          ecf2_ect_combination_rows(teacher_combination).each { csv << it }
          ecf2_mentor_combination_rows(teacher_combination).each { csv << it }
        end
      end
    end

    def ecf2_ect_combination_rows(teacher_combination)
      teacher_combination.ecf2_ect_combinations.map do |ecf2_ect_combination|
        row(combination: ecf2_ect_combination,
            participant_profile_type: "ect",
            ecf1_participant_profile_id: teacher_combination.ecf1_ect_profile_id)
      end
    end

    def ecf2_mentor_combination_rows(teacher_combination)
      teacher_combination.ecf2_mentor_combinations.map do |ecf2_mentor_combination|
        row(combination: ecf2_mentor_combination,
            participant_profile_type: "mentor",
            ecf1_participant_profile_id: teacher_combination.ecf1_mentor_profile_id)
      end
    end

  private

    def csv_headers
      %w[
        participant_profile_type
        ecf1_participant_profile_id
        school_urn
        cohort_year
        lead_provider_name
        induction_record_id
      ].freeze
    end

    def row(combination:, ecf1_participant_profile_id:, participant_profile_type:)
      ECF1CombinationRow.new(
        participant_profile_type:,
        ecf1_participant_profile_id:,
        school_urn: combination[39..44],
        cohort_year: combination[47..50],
        lead_provider_name: combination[53..-2],
        induction_record_id: combination[1..36]
      )
    end
  end
end
