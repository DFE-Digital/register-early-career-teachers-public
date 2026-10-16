namespace :product_review do
  desc "Set up an ECT at Abbey Grove reported with Golden Leaf but claimed by Umber during the placement (#4559)"
  task "4559" => :environment do
    abort("Only available for non-production environments") if Rails.env.production?

    if Teacher.exists?(trn: "0004559")
      puts "Scenario already set up — Helen Mirren (TRN 0004559) exists. Aborting."
      next
    end

    abbey_grove = School.find_by!(urn: 1_759_427)
    golden_leaf = AppropriateBodyPeriod.find_by!(name: "Golden Leaf Teaching School Hub")
    umber = AppropriateBodyPeriod.find_by!(name: "Umber Teaching School Hub")
    started_on = Date.new(2025, 9, 1)

    ApplicationRecord.transaction do
      teacher = Teacher.create!(trn: "0004559", trs_first_name: "Helen", trs_last_name: "Mirren", trs_induction_status: "InProgress", trs_qts_awarded_on: Date.new(2025, 7, 1))
      ect_at_school_period = ECTAtSchoolPeriod.create!(teacher:, school: abbey_grove, school_reported_appropriate_body: golden_leaf, email: "helen.mirren@example.com", working_pattern: "full_time", started_on:, finished_on: nil)
      TrainingPeriod.create!(ect_at_school_period:, training_programme: "school_led", started_on:, finished_on: nil)
      InductionPeriod.create!(teacher:, appropriate_body_period: umber, started_on: Date.new(2025, 10, 1), induction_programme: "fip", training_programme: "school_led")
    end

    puts "Helen Mirren (TRN 0004559) at Abbey Grove: school reported Golden Leaf, claimed by Umber on 1 October 2025."
  end
end
