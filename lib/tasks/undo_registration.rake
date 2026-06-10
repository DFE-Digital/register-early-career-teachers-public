namespace :support do
  desc "Undo a teacher registration made in error. Usage: rake support:undo_registration[ECTAtSchoolPeriod,123]"
  task :undo_registration, %i[period_type period_id] => :environment do |_task, args|
    period_types = {
      "ECTAtSchoolPeriod" => ECTAtSchoolPeriod,
      "MentorAtSchoolPeriod" => MentorAtSchoolPeriod
    }.freeze

    period_class = period_types.fetch(args[:period_type]) do
      raise ArgumentError, "period_type must be ECTAtSchoolPeriod or MentorAtSchoolPeriod"
    end

    period = period_class.find(args[:period_id])
    teacher = period.teacher

    puts "WARNING: This task undoes a teacher registration made in error."
    puts "  - If billable/refundable declarations exist: periods will be closed with today's date"
    puts "  - If no billable/refundable declarations: periods will be permanently deleted and the teacher record may be anonymised"
    puts "Teacher ID: #{teacher.id} | Period: #{period.class.name} #{period.id}"
    print "Enter the teacher ID to confirm: "

    abort "Undo cancelled." unless $stdin.gets&.strip == teacher.id.to_s

    Teachers::UndoRegistration.new(
      author: Events::SystemAuthor.new,
      at_school_period: period,
      reason: :registered_in_error
    ).undo!

    puts "Done. Undone #{period.class.name} #{period.id} for teacher #{teacher.id}"
  end
end
