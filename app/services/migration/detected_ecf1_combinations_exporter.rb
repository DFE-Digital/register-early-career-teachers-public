module Migration
  class DetectedECF1CombinationsExporter
    CACHE_KEY = "detected-ecf1-combinations-data"

    attr_reader :query

    ECF1CombinationRow = Struct.new(
      :participant_profile_type,
      :participant_profile_id,
      :school_urn,
      :cohort_year,
      :lead_provider_name,
      :induction_record_id,
      :migrated,
      keyword_init: true
    )

    def initialize
      @query = DataMigrationTeacherCombination.order(:api_id)
    end

    def generate_and_cache_csv
      Rails.cache.fetch(CACHE_KEY, expires_in: 24.hours) do
        generate_csv
      end
    end

    def generate_csv
      CSV.generate(headers: csv_headers, write_headers: true) do |csv|
        query.find_each(batch_size: 2_000) do |teacher_combination|
          ecf1_ect_combination_rows(teacher_combination).each { csv << it }
          ecf1_mentor_combination_rows(teacher_combination).each { csv << it }
        end
      end
    end

    def ecf1_ect_combination_rows(teacher_combination)
      teacher_combination.ecf1_ect_combinations.map do |ecf1_ect_combination|
        ecf2_ect_combination = teacher_combination.ecf2_ect_combinations.find { it[1..36] == ecf1_ect_combination[1..36] }

        row(combination: ecf1_ect_combination,
            participant_profile_type: "ect",
            participant_profile_id: teacher_combination.ecf1_ect_profile_id,
            migrated: ecf2_ect_combination.present?)
      end
    end

    def ecf1_mentor_combination_rows(teacher_combination)
      teacher_combination.ecf1_mentor_combinations.map do |ecf1_mentor_combination|
        ecf2_mentor_combination = teacher_combination.ecf2_mentor_combinations.find { it[1..36] == ecf1_mentor_combination[1..36] }

        row(combination: ecf1_mentor_combination,
            participant_profile_type: "mentor",
            participant_profile_id: teacher_combination.ecf1_mentor_profile_id,
            migrated: ecf2_mentor_combination.present?)
      end
    end

  private

    def csv_headers
      %w[
        participant_profile_type
        participant_profile_id
        school_urn
        cohort_year
        lead_provider_name
        induction_record_id
        migrated
      ].freeze
    end

    def row(combination:, participant_profile_id:, participant_profile_type:, migrated:)
      ECF1CombinationRow.new(
        participant_profile_type:,
        participant_profile_id:,
        school_urn: combination[39..44],
        cohort_year: combination[47..50],
        lead_provider_name: combination[53..-2],
        induction_record_id: combination[1..36],
        migrated:
      )
    end
  end
end
