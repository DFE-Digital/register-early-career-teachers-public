module Migration
  class InductionRecordExporter
    CACHE_KEY = "induction-record-data"

    def generate_and_cache_csv
      Rails.cache.fetch(CACHE_KEY, expires_in: 24.hours) do
        generate_csv
      end
    end

    def generate_csv
      CSV.generate(headers: true) do |csv|
        csv << csv_headers
        query.find_each(batch_size: 2_000) do |induction_record|
          csv << csv_row(induction_record)
        end
      end
    end

  private

    def csv_headers
      %w[induction_record_id start_date end_date right_way_round duration training_status school_transfer induction_record_created ect_participant_profile_id mentor_participant_profile_id urn challenged lead_provider_name].freeze
    end

    def csv_row(induction_record)
      [
        induction_record.id,
        induction_record.start_date.to_date,
        induction_record.end_date&.to_date,
        right_way_round?(induction_record),
        duration_of(induction_record),
        induction_record.training_status,
        induction_record.school_transfer,
        induction_record.created_at.to_date,
        ect_profile_id(induction_record),
        mentor_profile_id(induction_record),
        induction_record.induction_programme.school_cohort.school.urn,
        challenged?(induction_record),
        induction_record.induction_programme&.partnership&.lead_provider&.name,
      ]
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

    def query
      InductionRecord.eager_load(:participant_profile,
                                 :preferred_identity,
                                 induction_programme: { school_cohort: :school, partnership: :lead_provider })
    end
  end
end
