namespace :product_review do
  desc "Set up a teacher with a TRN merged into another in TRS at Abbey Grove for review (#4423)"
  task "4423" => :environment do
    if Teacher.exists?(trn: "0000081")
      puts "Scenario already set up — Nina Patel (TRN 0000081) exists. Aborting."
      next
    end

    # The merge event is recorded through ActiveJob and the timeline reads it
    # back, so it has to be written before the task returns.
    ActiveJob::Base.queue_adapter = :inline

    abbey_grove = School.find_by!(urn: 1_759_427)
    golden_leaf = AppropriateBodyPeriod.find_by!(name: "Golden Leaf Teaching School Hub")

    nina = nil

    ApplicationRecord.transaction do
      nina = Teacher.create!(
        trn: "0000081",
        trs_first_name: "Nina",
        trs_last_name: "Patel",
        trs_qts_awarded_on: Date.new(2023, 1, 1),
        trs_induction_status: "InProgress"
      )

      ECTAtSchoolPeriod.create!(teacher: nina, school: abbey_grove, started_on: Date.new(2024, 9, 1), finished_on: nil)

      InductionPeriod.create!(
        teacher: nina,
        appropriate_body_period: golden_leaf,
        started_on: Date.new(2024, 9, 1),
        finished_on: nil,
        induction_programme: "fip",
        training_programme: "provider_led"
      )
    end

    redirected_to = "0000082"

    Teachers::Manage.system_update(teacher: nina).mark_teacher_as_merged!(
      trs_data_last_refreshed_at: Time.zone.now,
      redirected_to:,
      event_body: "TRN #{nina.trn} redirects to TRN #{redirected_to}"
    )
  end
end
