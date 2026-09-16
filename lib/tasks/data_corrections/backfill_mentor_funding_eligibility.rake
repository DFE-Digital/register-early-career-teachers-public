namespace :data_corrections do
  desc <<~DESC.squish
    Backfill mentor funding eligibility for mentors with provider-led training
    and an ECT assignment.

    Usage:
      bundle exec rake "data_corrections:backfill_mentor_funding_eligibility[EXPECTED_COUNT]"
  DESC

  task :backfill_mentor_funding_eligibility,
       [:expected_count] => :environment do |_task, args|
    if args[:expected_count].blank?
      raise ArgumentError, "Expected count is required"
    end

    correction = DataCorrections::BackfillMentorFundingEligibility.new(expected_count: args[:expected_count])

    candidate_count = correction.preview.count
    expected_count = Integer(args[:expected_count])

    puts "Mentor funding eligibility backfill"
    puts "  Expected candidates: #{expected_count}"
    puts "  Candidates found in this environment: #{candidate_count}"
    puts

    unless candidate_count == expected_count
      abort "Candidate count does not match. No records were changed."
    end

    puts "This will:"
    puts "  - set mentor funding eligibility using the current time"
    puts "  - update relevant no payment declarations"
    puts "  - create funding eligibility audit events"
    puts
    print "Enter #{candidate_count} to confirm: "

    unless $stdin.gets&.strip == candidate_count.to_s
      abort "Correction cancelled. No records were changed."
    end

    corrected_teacher_ids = correction.call

    puts
    puts "Corrected #{corrected_teacher_ids.count} teachers."
    puts "Remaining candidates: #{correction.preview.count}"
  end
end
