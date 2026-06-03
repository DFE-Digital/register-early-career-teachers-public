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

    Teachers::Archive.new(
      author: Events::SystemAuthor.new,
      period:,
      reason: :registered_in_error
    ).archive

    puts "Done. Archived #{period.class.name} #{period.id} for teacher #{period.teacher.id}"
  end
end
