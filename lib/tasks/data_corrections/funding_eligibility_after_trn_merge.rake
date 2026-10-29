namespace :data_corrections do
  desc "Correct funding eligibility for teachers who have had a TRN merge"

  task :set_funding_eligibility_after_trn_merge, [:dry_run] => :environment do |_t, args|
    dry_run = args[:dry_run].nil? || ActiveModel::Type::Boolean.new.cast(args[:dry_run])

    puts("Dry run mode: #{dry_run}")

    author = Events::SystemAuthor.new

    failed_teachers = []

    affected_teachers = Teacher
      .joins(:events)
      .where(events: { event_type: :teacher_merged })
      .distinct

    affected_teachers.each do |teacher|
      puts "----------------------------------------"
      puts "Processing teacher with TRN: #{teacher.trn}"

      begin
        ActiveRecord::Base.transaction do
          # If merge has removed the ECT's eligibility data, set it based on the TRS induction start date, or registration date
          record_ect_event = false
          record_mentor_event = false

          if teacher.ect_first_became_eligible_for_training_at.nil? && teacher.ect_at_school_periods.any?
            puts "ECT eligibility is missing"
            if teacher.trs_induction_start_date.present?
              teacher.ect_first_became_eligible_for_training_at = teacher.trs_induction_start_date
              puts "Setting ECT eligibility based on TRS induction start date: #{teacher.trs_induction_start_date}"
              record_ect_event = true
            elsif teacher.trs_induction_status == "InProgress"
              ect_registered_on = teacher.ect_at_school_periods.earliest_first.first&.started_on
              teacher.ect_first_became_eligible_for_training_at = ect_registered_on
              puts "Setting ECT eligibility based on registration date: #{ect_registered_on}"
              record_ect_event = true
            else
              puts "ECT has not started induction"
            end
          else
            puts "ECT eligibility unchanged: #{teacher.ect_first_became_eligible_for_training_at}"
          end

          # If the mentor has a completed declaration, mark them as ineligible for funding
          earliest_completed_declaration = teacher
            .mentor_declarations
            .declaration_type_completed
            .billable_or_changeable
            .order(evidenced_at: :desc)
            .first

          if earliest_completed_declaration.present? && teacher.mentor_became_ineligible_for_funding_on.nil?
            teacher.mentor_became_ineligible_for_funding_on = earliest_completed_declaration.evidenced_at
            teacher.mentor_became_ineligible_for_funding_reason = "completed_declaration_received"

            puts "Marking mentor as ineligible for funding: #{earliest_completed_declaration.evidenced_at}"
          end

          # If merge has removed the mentor's eligibility data, set it based on the earliest training period start date
          if teacher.mentor_first_became_eligible_for_training_at.nil? &&
              teacher.mentor_became_ineligible_for_funding_on.nil? &&
              teacher.mentor_training_periods.any?

            training_started_on = teacher.mentor_training_periods.earliest_first.first.started_on

            teacher.mentor_first_became_eligible_for_training_at = training_started_on

            puts "Mentor eligibility is missing - setting based on earliest training period: #{training_started_on}"
            record_mentor_event = true
          else
            puts "Mentor eligibility unchanged: #{teacher.mentor_first_became_eligible_for_training_at}"
          end

          # If the ECT is exempt and has not been marked as ineligible for funding, set the ineligible date to today
          if teacher.trs_induction_status == "Exempt" && teacher.ect_became_ineligible_for_funding_on.nil?
            puts "ECT is exempt and not marked as ineligible for funding - setting ineligible date to today"
            teacher.ect_became_ineligible_for_funding_on = Date.current
          end

          teacher.save! unless dry_run

          # Mark submitted declarations as eligible for eligible ECTs
          # Submitted declarations have payment_status "no_payment"
          if teacher.ect_first_became_eligible_for_training_at.present?
            declarations = teacher.ect_declarations.payment_status_no_payment

            puts "Marking #{declarations.count} ECT declarations as eligible"

            Declarations::Actions::MarkDeclarationsEligible.new(declarations:, author:).mark unless dry_run
          end

          if teacher.mentor_first_became_eligible_for_training_at.present?
            declarations = teacher.mentor_declarations.payment_status_no_payment

            puts "Marking #{declarations.count} mentor declarations as eligible"

            Declarations::Actions::MarkDeclarationsEligible.new(declarations:, author:).mark unless dry_run
          end

          next if dry_run

          if record_ect_event
            puts "Recording ECT funding eligibility event"
            Events::Record.record_teacher_set_funding_eligibility_event!(
              author:,
              teacher:,
              teacher_type: "ECT",
              happened_at: Time.zone.now,
              modifications: teacher.saved_changes
            )
          end

          if record_mentor_event
            puts "Recording mentor funding eligibility event"
            Events::Record.record_teacher_set_funding_eligibility_event!(
              author:,
              teacher:,
              teacher_type: "Mentor",
              happened_at: Time.zone.now,
              modifications: teacher.saved_changes
            )
          end
        end
      rescue Declarations::Actions::MarkDeclarationsEligible::MissingPaymentStatementError => e
        puts("Failed to mark ECT declarations as eligible")
        failed_teachers << { trn: teacher.trn, error: e.class.name }
      rescue ActiveRecord::ActiveRecordError => e
        puts("Database error for TRN #{teacher.trn}: #{e.class} - #{e.message}")
        failed_teachers << { trn: teacher.trn, error: e.class.name }
      end
    end

    if failed_teachers.any?
      puts("Failed TRNs:")
      failed_teachers.uniq { |x| x[:trn] }.each do |entry|
        puts("#{entry[:trn]} (#{entry[:error]})")
      end
    end
  end
end
