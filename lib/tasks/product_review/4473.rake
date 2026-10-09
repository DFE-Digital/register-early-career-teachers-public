namespace :product_review do
  desc "Set up a teacher with a TRN merged into another in TRS #4473"
  task "4473" => :environment do
    # The merge event is recorded through ActiveJob and the timeline reads it
    # back, so it has to be written before the task returns.
    ActiveJob::Base.queue_adapter = :inline

    # Basic Happy Path (ECT)
    source = Teacher.find_by_trn("9000000")
    destination = Teacher.find_by_trn("9000002")

    source_mp = source.ect_at_school_periods.first.mentorship_periods.first
    destination_mp = destination.ect_at_school_periods.first.mentorship_periods.first

    source_tp = source.ect_at_school_periods.first.training_periods.first
    destination_tp = destination.ect_at_school_periods.first.training_periods.first

    destination_mp.update!(mentor_at_school_period_id: source_mp.mentor_at_school_period_id)

    FactoryBot.create(:declaration, :paid, training_period: source_tp)
    FactoryBot.create(:declaration, :voided, training_period: destination_tp)

    Teachers::Manage.system_update(teacher: source).mark_teacher_as_merged!(
      trs_data_last_refreshed_at: Time.zone.now,
      redirected_to: destination.trn,
      event_body: "TRN #{source.trn} redirects to TRN #{destination.trn}"
    )

    # Different Schedules
    source = Teacher.find_by_trn("9000001")
    destination = Teacher.find_by_trn("9000003")

    source.mentor_at_school_periods.first.training_periods.first
    destination_tp = destination.mentor_at_school_periods.first.training_periods.first

    january_schedule = Schedule.find_by(contract_period_year: 2025, identifier: "ecf-extended-january")
    destination_tp.update!(schedule: january_schedule)

    Teachers::Manage.system_update(teacher: source).mark_teacher_as_merged!(
      trs_data_last_refreshed_at: Time.zone.now,
      redirected_to: destination.trn,
      event_body: "TRN #{source.trn} redirects to TRN #{destination.trn}"
    )

    # ECT Periods at different schools which overlapp
    source = Teacher.find_by_trn("9000004")
    destination = Teacher.find_by_trn("9000006")

    Teachers::Manage.system_update(teacher: source).mark_teacher_as_merged!(
      trs_data_last_refreshed_at: Time.zone.now,
      redirected_to: destination.trn,
      event_body: "TRN #{source.trn} redirects to TRN #{destination.trn}"
    )

    # Different Withdrawl Reasons
    source = Teacher.find_by_trn("9000007")
    destination = Teacher.find_by_trn("9000009")
    source_tp = source.mentor_at_school_periods.first.training_periods.first
    destination_tp = destination.mentor_at_school_periods.first.training_periods.first

    finished_on = destination_tp.started_on + 1.month
    school_partnership = source_tp.school_partnership

    destination_tp.update!(
      withdrawal_reason: :moved_school,
      withdrawn_at: finished_on,
      finished_on:,
      school_partnership:
    )

    Teachers::Manage.system_update(teacher: source).mark_teacher_as_merged!(
      trs_data_last_refreshed_at: Time.zone.now,
      redirected_to: destination.trn,
      event_body: "TRN #{source.trn} redirects to TRN #{destination.trn}"
    )

    # Different Induction statuses
    source = Teacher.find_by_trn("9000008")
    destination = Teacher.find_by_trn("9000010")

    destination_tp = destination.ect_at_school_periods.first.training_periods.first
    source_tp = source.ect_at_school_periods.first.training_periods.first

    school_partnership = destination_tp.school_partnership
    schedule = destination_tp.schedule

    FactoryBot.create(:induction_period, :pass, teacher: source)
    source.update!(trs_induction_status: "Passed")
    source_tp.update!(school_partnership:, schedule:)

    FactoryBot.create(:induction_period, :fail, teacher: destination)
    destination.update!(trs_induction_status: "Failed")

    Teachers::Manage.system_update(teacher: source).mark_teacher_as_merged!(
      trs_data_last_refreshed_at: Time.zone.now,
      redirected_to: destination.trn,
      event_body: "TRN #{source.trn} redirects to TRN #{destination.trn}"
    )

    # Different Contract Periods
    source = Teacher.find_by_trn("9000006")
    destination = Teacher.find_by_trn("9000010")

    Teachers::Manage.system_update(teacher: source).mark_teacher_as_merged!(
      trs_data_last_refreshed_at: Time.zone.now,
      redirected_to: destination.trn,
      event_body: "TRN #{source.trn} redirects to TRN #{destination.trn}"
    )

    # Different Mentors
    source = Teacher.find_by_trn("9000012")
    destination = Teacher.find_by_trn("9000014")

    Teachers::Manage.system_update(teacher: source).mark_teacher_as_merged!(
      trs_data_last_refreshed_at: Time.zone.now,
      redirected_to: destination.trn,
      event_body: "TRN #{source.trn} redirects to TRN #{destination.trn}"
    )

    # Different Deferral Reasons
    source = Teacher.find_by_trn("9000017")
    destination = Teacher.find_by_trn("9000015")

    source_tp = source.mentor_at_school_periods.first.training_periods.first
    destination_tp = destination.mentor_at_school_periods.first.training_periods.first

    finished_on = "2027-01-01"
    school_partnership = source_tp.school_partnership
    schedule = source_tp.schedule

    destination_tp.update!(
      deferral_reason: :career_break,
      deferred_at: finished_on,
      finished_on:,
      school_partnership:,
      schedule:
    )

    Teachers::Manage.system_update(teacher: source).mark_teacher_as_merged!(
      trs_data_last_refreshed_at: Time.zone.now,
      redirected_to: destination.trn,
      event_body: "TRN #{source.trn} redirects to TRN #{destination.trn}"
    )

    # Basic Happy Path (Mentor)
    source = Teacher.find_by_trn("9000019")
    destination = Teacher.find_by_trn("9000021")

    source_mp = source.mentor_at_school_periods.first.mentorship_periods.first
    destination.mentor_at_school_periods.first.mentorship_periods.first

    source_mp.update!(finished_on: "2026-11-01")

    source_tp = source.mentor_at_school_periods.first.training_periods.first
    destination_tp = destination.mentor_at_school_periods.first.training_periods.first

    FactoryBot.create(:declaration, :paid, training_period: source_tp)
    FactoryBot.create(:declaration, :voided, training_period: destination_tp)

    Teachers::Manage.system_update(teacher: source).mark_teacher_as_merged!(
      trs_data_last_refreshed_at: Time.zone.now,
      redirected_to: destination.trn,
      event_body: "TRN #{source.trn} redirects to TRN #{destination.trn}"
    )

    # Non-overlapping (ECT)
    source = Teacher.find_by_trn("9000024")
    destination = Teacher.find_by_trn("9000026")

    source_ect = source.ect_at_school_periods.first
    source_mp = source_ect.mentorship_periods.first

    destination_ect = destination.ect_at_school_periods.first
    destination_mp = destination_ect.mentorship_periods.first

    source_tp = source_ect.training_periods.first
    destination_tp = destination_ect.training_periods.first

    destination_mp.update!(mentor_at_school_period_id: source_mp.mentor_at_school_period_id)

    source_tp.update!(finished_on: "2026-06-05")
    source_mp.update!(finished_on: "2026-06-05")
    source_ect.update!(finished_on: "2026-06-05")

    destination_tp.update!(finished_on: "2026-06-05")
    destination_mp.update!(finished_on: "2026-06-05")
    destination_ect.update!(finished_on: "2026-06-05")

    non_overlapping_ect = FactoryBot.create(
      :ect_at_school_period,
      :with_training_period,
      school: source_ect.school,
      teacher: source,
      started_on: "2026-07-01",
      finished_on: "2026-9-15"
    )

    FactoryBot.create(
      :mentorship_period,
      mentee: non_overlapping_ect,
      mentor: source_mp.mentor,
      started_on: "2026-07-01",
      finished_on: "2026-09-15"
    )

    FactoryBot.create(:declaration, :paid, training_period: source_tp)
    FactoryBot.create(:declaration, :voided, training_period: destination_tp)

    Teachers::Manage.system_update(teacher: source).mark_teacher_as_merged!(
      trs_data_last_refreshed_at: Time.zone.now,
      redirected_to: destination.trn,
      event_body: "TRN #{source.trn} redirects to TRN #{destination.trn}"
    )
  end

  desc "Merge the TRNs merged automatically #4473"
  task "4473_merge_teachers" => :environment do
    trns = [9_000_000, 9_000_001, 9_000_004, 9_000_006, 9_000_007, 9_000_008, 9_000_012, 9_000_017, 9_000_019, 9_000_024]

    trns.each do |trn|
      puts "\n"
      source = Teacher.find_by_trn(trn)

      next unless source

      puts "---------------"

      destination = Teacher.find_by_trn(source.trs_redirected_to)
      eligibility = Teachers::MergeTRN::Eligibility.new(teacher: source).can_be_merged?

      if eligibility
        puts "Teacher can be merged"
        puts "Attempting to merge TRN #{source.trn} into TRN #{destination.trn}"

        begin
          Teachers::MergeTRN.new(teacher: source).merge!

          puts "Teacher merged"
        rescue Teachers::MergeTRN::MentorshipPeriods::Merge::CannotMergePeriods, Teachers::MergeTRN::TrainingPeriods::Merge::CannotMergePeriods => e
          puts "Cannot merge mentorship periods: #{e.message}"
        end
      end

      next if eligibility

      puts "TRN #{source.trn} is not eligible"

      period_type = trn.to_i.even? ? :ect_at_school_period : :mentor_at_school_period

      if period_type == :ect_at_school_period && destination.present?
        ect_periods_at_different_schools_do_not_overlap =
          source.ect_at_school_periods.none? do |period|
            destination.ect_at_school_periods
              .where.not(school_id: period.school_id)
              .overlapping_with(period)
              .exists?
          end

        unless ect_periods_at_different_schools_do_not_overlap
          puts "ECT periods at different schools overlap"

          next
        end
      end

      periods = if period_type == :ect_at_school_period
                  source.ect_training_periods + destination.ect_training_periods
                else
                  source.mentor_training_periods + destination.mentor_training_periods
                end

      training_periods_have_same_contract_period = periods.map(&:contract_period).uniq.size <= 1

      unless training_periods_have_same_contract_period
        puts "Training periods do not have the same contract period"
        next
      end

      both_teachers_have_induction_periods = (source.induction_periods.any? && destination.induction_periods.any?)

      if both_teachers_have_induction_periods
        puts "Both teachers have induction periods"
        next
      end
    end
  end
end
