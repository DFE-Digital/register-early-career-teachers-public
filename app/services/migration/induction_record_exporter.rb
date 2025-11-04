module Migration
  class InductionRecordExporter
    CACHE_KEY = "induction-record-data"

    attr_reader :query

    InductionRecordRow = Struct.new(
      :induction_record_id,
      :start_date,
      :end_date,
      :right_way_round,
      :duration,
      :training_status,
      :school_transfer,
      :induction_record_created,
      :ect_participant_profile_id,
      :mentor_participant_profile_id,
      :urn,
      :challenged,
      :lead_provider_name,
      :cohort_year,
      keyword_init: true
    ) do
      def range = start_date..end_date
      def right_way_round? = right_way_round
      def wrong_way_round? = !right_way_round
      def withdrawn? = training_status == 'withdrawn'
      def school_transfer? = school_transfer
      def finished? = !end_date.nil?
      def finishes_after_other_starts?(other) = finished? && end_date > other.start_date
    end

    def initialize
      @query = base_query
    end

    def where_participant_profile_id_is(participant_profile_id)
      fail unless Migration::ParticipantProfile.exists?(participant_profile_id)

      @query = query.where(participant_profile_id:)

      self
    end

    def rows
      query.map { row(it) }
    end

    def generate_and_cache_csv
      Rails.cache.fetch(CACHE_KEY, expires_in: 24.hours) do
        generate_csv
      end
    end

    def generate_csv
      CSV.generate(headers: csv_headers, write_headers: true) do |csv|
        query.find_each(batch_size: 2_000) do |induction_record|
          csv << row(induction_record)
        end
      end
    end

  private

    def csv_headers
      %w[
        induction_record_id
        start_date
        end_date
        right_way_round
        duration
        training_status
        school_transfer
        induction_record_created
        ect_participant_profile_id
        mentor_participant_profile_id
        urn
        challenged
        lead_provider_name
        cohort_year
      ].freeze
    end

    def row(induction_record)
      InductionRecordRow.new(
        induction_record_id: induction_record.id,
        start_date: induction_record.start_date.to_date,
        end_date: induction_record.end_date&.to_date,
        right_way_round: right_way_round?(induction_record),
        duration: duration_of(induction_record),
        training_status: induction_record.training_status,
        school_transfer: induction_record.school_transfer,
        induction_record_created: induction_record.created_at.to_date,
        ect_participant_profile_id: ect_profile_id(induction_record),
        mentor_participant_profile_id: mentor_profile_id(induction_record),
        urn: induction_record.induction_programme.school_cohort.school.urn,
        challenged: challenged?(induction_record),
        lead_provider_name: induction_record.induction_programme&.partnership&.lead_provider&.name,
        cohort_year: induction_record.schedule.cohort.start_year
      )
    end

    def ect_profile_id(induction_record)
      induction_record.participant_profile_id if induction_record.participant_profile.type == "ParticipantProfile::ECT"
    end

    def mentor_profile_id(induction_record)
      induction_record.participant_profile_id if induction_record.participant_profile.type == "ParticipantProfile::Mentor"
    end

    def challenged?(induction_record)
      return nil if induction_record.induction_programme&.partnership.blank?

      induction_record.induction_programme.partnership.challenged_at.present?
    end

    def right_way_round?(induction_record)
      return true if induction_record.end_date.blank?

      induction_record.start_date < induction_record.end_date
    end

    def duration_of(induction_record)
      return nil if induction_record.end_date.blank?

      (induction_record.end_date.to_date - induction_record.start_date.to_date).to_i
    end

    def base_query
      InductionRecord.eager_load(:participant_profile,
                                 :preferred_identity,
                                 schedule: :cohort,
                                 induction_programme: { school_cohort: :school, partnership: :lead_provider })
                     .order(start_date: :asc)
    end
  end
end
