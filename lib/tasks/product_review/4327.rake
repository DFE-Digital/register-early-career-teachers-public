namespace :product_review do
  desc "Set up a teacher with a TRN deactivated in TRS at Abbey Grove for review (#4327)"
  task "4327" => :environment do
    if Teacher.exists?(trn: "0000080")
      puts "Scenario already set up — Ruth Wilson (TRN 0000080) exists. Aborting."
      next
    end

    # The deactivation event is recorded through ActiveJob and the timeline
    # reads it back, so it has to be written before the task returns.
    ActiveJob::Base.queue_adapter = :inline

    abbey_grove = School.find_by!(urn: 1_759_427)
    golden_leaf = AppropriateBodyPeriod.find_by!(name: "Golden Leaf Teaching School Hub")

    ruth = nil

    ApplicationRecord.transaction do
      ruth = Teacher.create!(
        trn: "0000080",
        trs_first_name: "Ruth",
        trs_last_name: "Wilson",
        trs_qts_awarded_on: Date.new(2023, 1, 1),
        trs_induction_status: "InProgress"
      )

      ECTAtSchoolPeriod.create!(teacher: ruth, school: abbey_grove, started_on: Date.new(2024, 9, 1), finished_on: nil)

      InductionPeriod.create!(
        teacher: ruth,
        appropriate_body_period: golden_leaf,
        started_on: Date.new(2024, 9, 1),
        finished_on: nil,
        induction_programme: "fip",
        training_programme: "provider_led"
      )
    end

    Teachers::Manage.system_update(teacher: ruth).mark_teacher_as_deactivated!(trs_data_last_refreshed_at: Time.zone.now)
  end
end
