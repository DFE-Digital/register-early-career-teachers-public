namespace :product_review do
  desc "Set up a teacher with a TRN merged into another in TRS #4473"
  task "4473" => :environment do
    # The merge event is recorded through ActiveJob and the timeline reads it
    # back, so it has to be written before the task returns.
    ActiveJob::Base.queue_adapter = :inline

    source = Teacher.find_by_trn("9000000")
    destination = Teacher.find_by_trn("9000001")

    FactoryBot.create(:induction_period,
                      teacher: source,
                      started_on: "2024-01-01",
                      finished_on: "2025-01-01",
                      number_of_terms: 1)

    FactoryBot.create(:induction_period,
                      teacher: destination,
                      started_on: "2025-01-01",
                      finished_on: "2026-01-01",
                      number_of_terms: 1)

    source.update!(
      trs_induction_status: "Failed",
      ect_first_became_eligible_for_training_at: "2024-01-01",
      ect_became_ineligible_for_funding_on: "2025-01-01",
      ect_payments_frozen_year: "2024"
    )

    destination.update!(
      trs_induction_status: "Passed",
      ect_first_became_eligible_for_training_at: "2025-01-01",
      ect_became_ineligible_for_funding_on: "2026-01-01",
      ect_payments_frozen_year: "2025"
    )

    Teachers::Manage.system_update(teacher: source).mark_teacher_as_merged!(
      trs_data_last_refreshed_at: Time.zone.now,
      redirected_to: destination.trn,
      event_body: "TRN #{source.trn} redirects to TRN #{destination.trn}"
    )

    source = Teacher.find_by_trn("9000002")
    destination = Teacher.find_by_trn("9000003")

    source.update!(
      mentor_first_became_eligible_for_training_at: "2024-01-01",
      mentor_became_ineligible_for_funding_on: "2025-01-01",
      mentor_became_ineligible_for_funding_reason: "started_not_completed",
      mentor_payments_frozen_year: "2024"
    )

    destination.update!(
      mentor_first_became_eligible_for_training_at: "2025-01-01",
      mentor_became_ineligible_for_funding_on: "2026-01-01",
      mentor_became_ineligible_for_funding_reason: "completed_declaration_received",
      mentor_payments_frozen_year: "2025"
    )

    Teachers::Manage.system_update(teacher: source).mark_teacher_as_merged!(
      trs_data_last_refreshed_at: Time.zone.now,
      redirected_to: destination.trn,
      event_body: "TRN #{source.trn} redirects to TRN #{destination.trn}"
    )

    source = Teacher.find_by_trn("9000004")
    destination = Teacher.find_by_trn("9000005")

    FactoryBot.create(:induction_period,
                      :unfinished,
                      teacher: source,
                      started_on: "2026-01-01")

    FactoryBot.create(:induction_period,
                      teacher: destination,
                      started_on: "2024-01-01",
                      finished_on: "2025-01-01",
                      number_of_terms: 1)

    source.update!(
      trs_induction_status: "InProgress",
      ect_first_became_eligible_for_training_at: "2026-01-01"
    )

    destination.update!(
      trs_induction_status: "Failed",
      ect_first_became_eligible_for_training_at: "2024-01-01"
    )

    Teachers::Manage.system_update(teacher: source).mark_teacher_as_merged!(
      trs_data_last_refreshed_at: Time.zone.now,
      redirected_to: destination.trn,
      event_body: "TRN #{source.trn} redirects to TRN #{destination.trn}"
    )

    source = Teacher.find_by_trn("9000006")
    destination = Teacher.find_by_trn("9000007")

    FactoryBot.create(:induction_period,
                      :unfinished,
                      teacher: source,
                      started_on: "2025-01-01")

    source.update!(
      trs_induction_status: "InProgress",
      ect_first_became_eligible_for_training_at: "2025-01-01"
    )

    destination.update!(
      trs_induction_status: "RequiredToComplete"
    )

    Teachers::Manage.system_update(teacher: source).mark_teacher_as_merged!(
      trs_data_last_refreshed_at: Time.zone.now,
      redirected_to: destination.trn,
      event_body: "TRN #{source.trn} redirects to TRN #{destination.trn}"
    )

    source = Teacher.find_by_trn("9000008")
    destination = Teacher.find_by_trn("9000009")

    FactoryBot.create(:induction_period,
                      :unfinished,
                      teacher: destination,
                      started_on: "2025-01-01")

    source.update!(
      trs_induction_status: "RequiredToComplete"
    )

    destination.update!(
      trs_induction_status: "InProgress",
      ect_first_became_eligible_for_training_at: "2025-01-01"
    )

    Teachers::Manage.system_update(teacher: source).mark_teacher_as_merged!(
      trs_data_last_refreshed_at: Time.zone.now,
      redirected_to: destination.trn,
      event_body: "TRN #{source.trn} redirects to TRN #{destination.trn}"
    )
  end

  desc "Merge the TRNs merged automatically #4473"
  task "4473_merge_teachers" => :environment do
    trns = [9_000_000, 9_000_002, 9_000_004, 9_000_006, 9_000_008]

    trns.each do |trn|
      source = Teacher.find_by_trn(trn)
      Teacher.find_by_trn((trn + 1).to_s)

      Teachers::MergeTRN.new(teacher: source).merge!
    end
  end
end
