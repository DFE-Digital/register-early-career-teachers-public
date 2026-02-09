module Migration
  class TeacherCombinationsExporter
    CACHE_KEY = "teacher-combinations-data"

    attr_reader :query

    TeacherCombinationRow = Struct.new(
      :api_id,
      :ecf1_ect_profile_id,
      :ecf1_mentor_profile_id,
      :ecf1_ect_combinations,
      :ecf2_ect_combinations,
      :ecf1_mentor_combinations,
      :ecf2_mentor_combinations,
      :ecf1_ect_combinations_count,
      :ecf2_ect_combinations_count,
      :ecf1_mentor_combinations_count,
      :ecf2_mentor_combinations_count,
      :successful,
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
          csv << row(teacher_combination)
        end
      end
    end

  private

    def csv_headers
      %w[
        api_id
        ecf1_ect_profile_id
        ecf1_mentor_profile_id
        ecf1_ect_combinations
        ecf2_ect_combinations
        ecf1_mentor_combinations
        ecf2_mentor_combinations
        ecf1_ect_combinations_count
        ecf2_ect_combinations_count
        ecf1_mentor_combinations_count
        ecf2_mentor_combinations_count
        successful
      ].freeze
    end

    def row(teacher_combination)
      TeacherCombinationRow.new(
        api_id: teacher_combination.api_id,
        ecf1_ect_profile_id: teacher_combination.ecf1_ect_profile_id,
        ecf1_mentor_profile_id: teacher_combination.ecf1_mentor_profile_id,
        ecf1_ect_combinations: teacher_combination.ecf1_ect_combinations,
        ecf2_ect_combinations: teacher_combination.ecf2_ect_combinations,
        ecf1_mentor_combinations: teacher_combination.ecf1_mentor_combinations,
        ecf2_mentor_combinations: teacher_combination.ecf2_mentor_combinations,
        ecf1_ect_combinations_count: teacher_combination.ecf1_ect_combinations_count,
        ecf2_ect_combinations_count: teacher_combination.ecf2_ect_combinations_count,
        ecf1_mentor_combinations_count: teacher_combination.ecf1_mentor_combinations_count,
        ecf2_mentor_combinations_count: teacher_combination.ecf2_mentor_combinations_count,
        successful: successful?(teacher_combination)
      )
    end

    def successful?(teacher_combination)
      teacher_combination.ecf1_ect_combinations_count == teacher_combination.ecf2_ect_combinations_count &&
        teacher_combination.ecf1_mentor_combinations_count == teacher_combination.ecf2_mentor_combinations_count
    end
  end
end
