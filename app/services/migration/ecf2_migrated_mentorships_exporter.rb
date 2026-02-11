module Migration
  class ECF2MigratedMentorshipsExporter
    CACHE_KEY = "ecf2-migrated-mentorships-data"

    attr_reader :query

    ECF2MentorshipRow = Struct.new(
      :ect_participant_profile_id,
      :mentor_participant_profile_id,
      :started_on,
      :finished_on,
      :ecf_start_induction_record_id,
      :ecf_end_induction_record_id,
      keyword_init: true
    )

    def initialize
      @query = DataMigrationTeacherCombination.order(:trn)
    end

    def generate_and_cache_csv
      Rails.cache.fetch(CACHE_KEY, expires_in: 1.minute) do
        generate_csv
      end
    end

    def generate_csv
      CSV.generate(headers: csv_headers, write_headers: true) do |csv|
        query.find_each(batch_size: 2_000) do |teacher_combination|
          ecf2_mentorships_rows(teacher_combination).each { csv << it }
        end
      end
    end

    def ecf2_mentorships_rows(teacher_combination)
      teacher_combination.ecf2_mentorships.map do |ecf2_mentorship|
        row(mentorship: ecf2_mentorship,
            ect_participant_profile_id: teacher_combination.ecf1_ect_profile_id)
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
      ].freeze
    end

    def row(mentorship:, ect_participant_profile_id:)
      ECF2MentorshipRow.new(
        ect_participant_profile_id:,
        mentor_participant_profile_id: mentorship[77..112],
        started_on: mentorship[115..124],
        finished_on: mentorship[127..-2].presence,
        ecf_start_induction_record_id: mentorship[1..36],
        ecf_end_induction_record_id: mentorship[39..74]
      )
    end
  end
end
