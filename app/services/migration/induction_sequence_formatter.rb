# frozen_string_literal: true

# rubocop:disable Rails/Output
module Migration
  # Formats and displays induction sequence analysis results to the console
  class InductionSequenceFormatter
    HEADER_SEPARATOR_LENGTH = 80
    SUB_SEPARATOR_LENGTH = 60

    def initialize(results)
      @results = results
    end

    def display_results
      display_header
      display_participants
      display_summary
    end

  private

    def display_header
      puts "\n" + "=" * HEADER_SEPARATOR_LENGTH
      puts "COMPLETE INDUCTION TIMELINE BY LEAD PROVIDER"
      puts "=" * HEADER_SEPARATOR_LENGTH
    end

    def display_participants
      grouped_results = @results.group_by { |r| r[:participant_id] }

      grouped_results.each do |participant_id, participant_results|
        display_participant_summary(participant_id, participant_results)
      end
    end

    def display_participant_summary(participant_id, participant_results)
      first_result = participant_results.first

      puts "\n👤 Participant ID: #{participant_id}"
      puts "   Type: #{first_result[:participant_type]}"

      display_participant_totals(participant_results)

      participant_results.each do |result|
        display_provider_details(result)
      end

      puts "\n   " + "-" * SUB_SEPARATOR_LENGTH
    end

    def display_participant_totals(participant_results)
      total_records = participant_results.sum { |r| r[:total_record_count] }
      total_null_end_dates = participant_results.sum { |r| r[:null_end_date_count] }

      puts "   Total induction records: #{total_records}"
      puts "   Records with NULL end_date: #{total_null_end_dates}"
    end

    def display_provider_details(result)
      puts "\n   🏢 Lead Provider: #{result[:lead_provider_name]}"
      puts "      Total records: #{result[:total_record_count]} (#{result[:null_end_date_count]} with NULL end_date)"
      puts "      Schools: #{result[:schools].join(', ')}" if result[:schools].any?
      puts "      Programme Types: #{result[:programme_types].join(', ')}" if result[:programme_types].any?
      puts "      Total Days with Provider: #{result[:total_days]} days"

      display_timeline(result[:provider_periods])
    end

    def display_timeline(provider_periods)
      puts "\n      🗓️ COMPLETE TIMELINE:"

      provider_periods.each do |period|
        display_period_details(period)
      end
    end

    def display_period_details(period)
      duration_text = format_duration(period[:duration_days])
      end_date_text = format_end_date(period)

      puts "         • Record #{period[:record_id]}: #{period[:start_date]} → #{end_date_text}"

      display_period_inference(period)
      display_period_metadata(period, duration_text)
    end

    def display_period_inference(period)
      if period[:next_record_id] && !period[:explicit_end_date]
        puts "           End date inferred from record: #{period[:next_record_id]}"
      end
    end

    def display_period_metadata(period, duration_text)
      puts "           Created date: #{period[:created_at]}"
      puts "           Duration: #{duration_text}"
      puts "           Period status: #{period[:status]}"
      puts "           School: #{period[:school]}" if period[:school]
      puts "           School URN: #{period[:school_urn]}" if period[:school_urn]
      puts "           Mentor profile id : #{period[:mentor_profile_id]}" if period[:mentor_profile_id]
      puts "           Induction status: #{period[:induction_status]}" if period[:induction_status]
      puts "           Training status: #{period[:training_status]}" if period[:training_status]
      puts "           Programme type: #{period[:programme]}" if period[:programme]
      puts "           Core Induction Programme: #{period[:core_induction_programme]}" if period[:core_induction_programme]
      puts "           Programme id: #{period[:programme_id]}" if period[:programme_id]
      puts "           Partnership id: #{period[:partnership_id]}" if period[:partnership_id]
    end

    def format_duration(duration_days)
      duration_days ? "#{duration_days} days" : "Unknown duration"
    end

    def format_end_date(period)
      if period[:explicit_end_date]
        period[:end_date].to_s
      elsif period[:end_date]
        "#{period[:end_date]} (inferred)"
      else
        "Ongoing"
      end
    end

    def display_summary
      puts "\n📝 SUMMARY:"
      puts "   Total problematic participants: #{count_unique_participants}"
      puts "   Total induction records: #{sum_total_records}"
      puts "   Total NULL end_date records: #{sum_null_end_date_records}"
      puts "   Lead providers involved: #{list_lead_providers.join(', ')}"
    end

    def count_unique_participants
      @results.group_by { |r| r[:participant_id] }.count
    end

    def sum_total_records
      @results.sum { |r| r[:total_record_count] }
    end

    def sum_null_end_date_records
      @results.sum { |r| r[:null_end_date_count] }
    end

    def list_lead_providers
      @results.map { |r| r[:lead_provider_name] }.uniq.sort
    end
  end
end
# rubocop:enable Rails/Output
