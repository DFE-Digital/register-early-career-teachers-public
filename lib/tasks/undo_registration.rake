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

    at_school_period = period_class.find(args[:period_id])
    teacher = at_school_period.teacher

    training_periods = at_school_period.training_periods.order(:started_on)
    mentorship_periods = at_school_period.mentorship_periods.order(:started_on)

    billable_or_refundable_declarations_exist =
      Declaration
        .where(training_period: training_periods)
        .merge(Declaration.billable.or(Declaration.refundable))
        .exists?

    puts "WARNING: This task undoes a teacher registration made in error."
    puts
    puts "Teacher ID: #{teacher.id}"
    puts "At-school period: #{at_school_period.class.name} ID: #{at_school_period.id}"
    puts "At-school period dates: #{at_school_period.started_on} to #{at_school_period.finished_on || 'ongoing'}"
    puts

    puts "Action:"
    if billable_or_refundable_declarations_exist
      puts "  - Billable/refundable declarations exist"
      puts "  - Open linked periods will be finished"
      puts "  - Existing finished periods will not be changed"
    else
      puts "  - No billable/refundable declarations exist"
      puts "  - Linked training periods will be permanently deleted"
      puts "  - Linked mentorship periods will be permanently deleted"
      puts "  - The at-school period will be permanently deleted"
    end
    puts

    puts "Linked training periods:"
    if training_periods.any?
      training_periods.each do |training_period|
        declaration_summary = training_period.declarations.map do |declaration|
          "##{declaration.id} payment: #{declaration.payment_status}, clawback: #{declaration.clawback_status}"
        end

        puts "  - #{training_period.id}: #{training_period.started_on} to #{training_period.finished_on || 'ongoing'}"
        puts "    declarations: #{declaration_summary.any? ? declaration_summary.join('; ') : 'none'}"
      end
    else
      puts "  none"
    end
    puts

    puts "Linked mentorship periods:"
    if mentorship_periods.any?
      mentorship_periods.each do |mentorship_period|
        puts "  - #{mentorship_period.id}: #{mentorship_period.started_on} to #{mentorship_period.finished_on || 'ongoing'}"
      end
    else
      puts "  none"
    end
    puts

    if mentorship_periods.many?
      puts "WARNING: This period has #{mentorship_periods.count} linked mentorship periods."
      puts "Only continue if all linked mentorship periods are part of the erroneous registration."
      puts
    end

    other_ect_periods = teacher.ect_at_school_periods.where.not(id: at_school_period.id)
    other_mentor_periods = teacher.mentor_at_school_periods.where.not(id: at_school_period.id)
    induction_periods = teacher.induction_periods

    puts "Other teacher records:"
    puts "  Other ECT at-school periods: #{other_ect_periods.ids.presence || 'none'}"
    puts "  Other mentor at-school periods: #{other_mentor_periods.ids.presence || 'none'}"
    puts "  Induction periods: #{induction_periods.ids.presence || 'none'}"
    puts

    if billable_or_refundable_declarations_exist
      puts "Teacher will NOT be anonymised because billable/refundable declarations exist."
    elsif other_ect_periods.exists? || other_mentor_periods.exists? || induction_periods.exists?
      puts "Teacher will NOT be anonymised because other teacher records remain."
    else
      puts "Teacher is expected to be anonymised after the targeted registration is removed."
    end
    puts

    print "Enter the teacher ID to confirm: "
    abort "Undo cancelled." unless $stdin.gets&.strip == teacher.id.to_s

    Teachers::UndoRegistration.new(
      author: Events::SystemAuthor.new,
      at_school_period:,
      reason: :registered_in_error
    ).undo!

    puts "Done. Registration undone for #{at_school_period.class.name} #{at_school_period.id} and teacher #{teacher.id}"
  end
end
