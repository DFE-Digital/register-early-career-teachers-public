namespace :support do
  desc "Archive a teacher registration made in error. Usage: rake support:archive_teacher[ECTAtSchoolPeriod,123]"
  task :archive_teacher, %i[period_type period_id] => :environment do |_task, args|
    period_types = {
      "ECTAtSchoolPeriod" => ECTAtSchoolPeriod,
      "MentorAtSchoolPeriod" => MentorAtSchoolPeriod
    }.freeze

    period_class = period_types.fetch(args[:period_type]) do
      raise ArgumentError, "period_type must be ECTAtSchoolPeriod or MentorAtSchoolPeriod"
    end

    period = period_class.find(args[:period_id])
    teacher = period.teacher

    puts "WARNING: This task archives a teacher registration made in error."
    puts "  - If billable/refundable declarations exist: periods will be closed with today's date"
    puts "  - If no billable/refundable declarations: periods will be permanently deleted and the teacher record may be anonymised"
    puts "Teacher ID: #{teacher.id} | Period: #{period.class.name} #{period.id}"
    print "Type ARCHIVE to confirm: "

    abort "Archive cancelled." unless $stdin.gets&.strip == "ARCHIVE"

    Teachers::Archive.new(
      author: Events::SystemAuthor.new,
      period:,
      reason: :registered_in_error
    ).archive

    puts "Done. Archived #{period.class.name} #{period.id} for teacher #{teacher.id}"
  end
end
