module Migration
  # Analyses induction sequences for participant profiles to identify
  # timeline gaps, overlaps, and data quality issues during migration
  class InductionSequenceAnalyser
    DEFAULT_BATCH_SIZE = 1000

    def initialize(participant_profiles = nil, batch_size: DEFAULT_BATCH_SIZE)
      @participant_profiles = validate_participant_profiles(participant_profiles)
      @batch_size = batch_size
    end

    # Perform the analysis on the participant profiles
    def analyse
      results = []

      if @participant_profiles.respond_to?(:find_each)
        @participant_profiles.find_each(batch_size: @batch_size) do |participant_profile|
          participant_results = analyse_participant_records(participant_profile)
          results.concat(participant_results)
        end
      else
        @participant_profiles.each do |participant_profile|
          participant_results = analyse_participant_records(participant_profile)
          results.concat(participant_results)
        end
      end

      results
    end

  private

    def validate_participant_profiles(participant_profiles)
      unless participant_profiles.respond_to?(:each)
        raise ArgumentError, "Expected enumerable participant profiles, got #{participant_profiles.class}"
      end

      participant_profiles
    end

    def analyse_participant_records(participant_profile)
      # Get ALL induction records to understand the complete timeline
      all_records = fetch_induction_records(participant_profile)

      # Group ALL records by lead provider
      records_by_provider = group_records_by_provider(all_records)

      build_participant_results(participant_profile, records_by_provider)
    end

    def fetch_induction_records(participant_profile)
      participant_profile
        .induction_records
        .includes(
          :lead_provider,
          :delivery_partner,
          :school,
          induction_programme: :partnership
        )
        .order(:start_date, :created_at)
    end

    def group_records_by_provider(records)
      records.group_by do |record|
        record.lead_provider&.name || "No Lead Provider"
      end
    end

    def build_participant_results(participant_profile, records_by_provider)
      participant_results = []

      records_by_provider.each do |provider_name, records|
        provider_periods = build_timeline_periods(records)
        null_end_date_count = count_null_end_dates(records)

        result = {
          participant_id: participant_profile.id,
          participant_type: participant_profile.type,
          lead_provider_name: provider_name,
          total_record_count: records.count,
          null_end_date_count:,
          record_ids: records.map(&:id).sort,
          provider_periods:,
          total_days: calculate_total_days(provider_periods),
          schools: extract_unique_schools(records),
          programme_types: extract_unique_programme_types(records),
        }

        participant_results << result
      end

      participant_results
    end

    def build_timeline_periods(provider_records)
      provider_records.map.with_index { |record, index|
        begin
          build_period(record, provider_records, index)
        rescue StandardError => e
          Rails.logger.error "InductionSequenceAnalyser: Failed to process record #{record.id}: #{e.message}"
          nil
        end
      }.compact
    end

    def build_period(record, provider_records, index)
      next_record = provider_records[index + 1] if index < provider_records.length - 1
      next_record_id = next_record&.id

      start_date = record.start_date
      end_date = determine_end_date(record, next_record)
      duration_days = calculate_duration(start_date, end_date)

      {
        record_id: record.id,
        created_at: record.created_at,
        start_date:,
        end_date:,
        explicit_end_date: record.end_date.present?,
        next_record_id:,
        duration_days:,
        status: determine_period_status(record),
        school: record.school&.name,
        school_urn: record.school&.urn,
        mentor_profile_id: record.mentor_profile_id,
        programme: record.induction_programme&.training_programme,
        core_induction_programme: record.induction_programme.core_induction_programme&.name,
        programme_id: record.induction_programme_id,
        partnership_id: record.induction_programme&.partnership_id,
        delivery_partner: record.delivery_partner&.name,
        induction_status: record.induction_status,
        training_status: record.training_status,
      }
    end

    def determine_end_date(record, next_record)
      # Use explicit end_date if present
      return record.end_date if record.end_date.present?

      # Otherwise, use next record's start_date as this record's end_date
      next_record&.start_date
    end

    def determine_period_status(record)
      record.end_date.present? ? "Completed" : "Ongoing"
    end

    def count_null_end_dates(records)
      records.count { |r| r.end_date.nil? }
    end

    def calculate_total_days(provider_periods)
      provider_periods.sum { |p| p[:duration_days] || 0 }
    end

    def extract_unique_schools(records)
      records.map { |r| r.school&.name }.compact.uniq
    end

    def extract_unique_programme_types(records)
      records.map { |r| r.induction_programme&.training_programme }.compact.uniq
    end

    def calculate_duration(start_date, end_date)
      return unless start_date

      # Ensure both values are Date objects before subtraction.
      # If end_date is nil (e.g. an ongoing record), use the
      # current date to calculate duration up to today.
      start_date = start_date.to_date
      end_date = end_date&.to_date || Date.current

      (end_date - start_date).to_i
    end
  end
end
