namespace :product_review do
  desc "Set up two exempt ECTs at Abbey Grove, one without a mentor and one with (#4555)"
  task "4555" => :environment do
    abort("Only available for non-production environments") if Rails.env.production?

    if Teacher.exists?(trn: "0000100")
      puts "Scenario already set up — Rachel Weisz (TRN 0000100) exists. Aborting."
      next
    end

    abbey_grove = School.find_by!(urn: 1_759_427)
    started_on = Date.new(2025, 9, 1)

    ApplicationRecord.transaction do
      unmentored = Teacher.create!(trn: "0000100", trs_first_name: "Rachel", trs_last_name: "Weisz", trs_induction_status: "Exempt")
      unmentored_period = ECTAtSchoolPeriod.create!(teacher: unmentored, school: abbey_grove, started_on:, finished_on: nil)
      TrainingPeriod.create!(ect_at_school_period: unmentored_period, training_programme: "school_led", started_on:, finished_on: nil)

      mentored = Teacher.create!(trn: "0000101", trs_first_name: "Tom", trs_last_name: "Hiddleston", trs_induction_status: "Exempt")
      mentored_period = ECTAtSchoolPeriod.create!(teacher: mentored, school: abbey_grove, started_on:, finished_on: nil)
      TrainingPeriod.create!(ect_at_school_period: mentored_period, training_programme: "school_led", started_on:, finished_on: nil)

      mentor = Teacher.create!(trn: "0000102", trs_first_name: "Olivia", trs_last_name: "Williams", trs_qts_awarded_on: Date.new(2020, 7, 1))
      mentor_at_school_period = MentorAtSchoolPeriod.create!(teacher: mentor, school: abbey_grove, started_on:, finished_on: nil)
      MentorshipPeriod.create!(mentee: mentored_period, mentor: mentor_at_school_period, started_on:, finished_on: nil)
    end

    puts "Exempt ECTs at Abbey Grove School: Rachel Weisz (TRN 0000100) with no mentor, Tom Hiddleston (TRN 0000101) mentored by Olivia Williams."
  end
end
