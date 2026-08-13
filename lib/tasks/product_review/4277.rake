namespace :product_review do
  desc "Close schools that GIAS later gives a successor link to, for the post-closure link queries (#4277)"
  task "4277" => :environment do
    if Teacher.exists?(trn: "0000070")
      puts "Scenario already set up — Randall Boggs (TRN 0000070) exists. Aborting."
      next
    end

    # Close records its events through ActiveJob and the Blazer queries read
    # those events, so they have to be written before the task returns.
    ActiveJob::Base.queue_adapter = :inline

    frank_mccay = GIAS::School.find_by!(urn: 9_123_505)
    monsters_junior = GIAS::School.find_by!(urn: 9_123_506)

    ApplicationRecord.transaction do
      Scenario4277.close_school!(frank_mccay)
      Scenario4277.link_to_successor!(frank_mccay, monsters_junior, GIAS::SchoolLink::SUCCESSOR)

      waternoose = Scenario4277.create_gias_school!(
        urn: 9_123_510,
        name: "Henry J. Waternoose Preparatory School",
        status: :closed,
        closed_on: Date.new(2026, 5, 31)
      )
      celia_mae = Scenario4277.create_gias_school!(urn: 9_123_511, name: "Celia Mae Academy", status: :open)

      randall = Scenario4277.create_teacher!("0000070", "Randall", "Boggs")
      fungus = Scenario4277.create_teacher!("0000071", "Fungus", "Bile")
      needleman = Scenario4277.create_teacher!("0000072", "Needleman", "Smitty")

      ECTAtSchoolPeriod.create!(teacher: randall, school: waternoose.school, started_on: Date.new(2025, 9, 1), finished_on: nil)
      MentorAtSchoolPeriod.create!(teacher: fungus, school: waternoose.school, started_on: Date.new(2025, 9, 1), finished_on: nil)
      ECTAtSchoolPeriod.create!(teacher: needleman, school: waternoose.school, started_on: Date.new(2026, 9, 1), finished_on: nil)

      Scenario4277.close_school!(waternoose)
      Scenario4277.link_to_successor!(waternoose, celia_mae, GIAS::SchoolLink::SUCCESSOR_SPLIT)

      ECTAtSchoolPeriod.create!(teacher: randall, school: celia_mae.school, started_on: Date.new(2026, 9, 1), finished_on: nil)
    end

    require Rails.root.join("db/seeds/blazer_queries/post_closure_school_links")
    queries = BlazerQueries::PostClosureSchoolLinks.sync!

    puts
    puts "=" * 78
    puts "  Schools linked to a successor after we closed them (#4277)"
    puts "=" * 78
    puts
    puts "  State seeded by this task:"
    puts "    - Frank McCay Technical College (9123505), closed 30 April 2026 with 3 ECTs"
    puts "      and 3 mentors, since linked to Monsters Junior School (9123506) as its"
    puts "      Successor. Monsters Junior is not registered in RECT."
    puts "    - Henry J. Waternoose Preparatory School (9123510), closed 31 May 2026,"
    puts "      since linked to Celia Mae Academy (9123511) as a split school:"
    puts "        - Randall Boggs (ECT) had his period finished at the closure, and has"
    puts "          since been re-registered at Celia Mae Academy"
    puts "        - Fungus Bile (mentor) had his period finished at the closure"
    puts "        - Needleman Smitty (ECT) was due to start in September and had his"
    puts "          registration deleted by the closure"
    puts
    puts "  To verify:"
    puts "    1. Sign in as Daphne Blake (DfE staff) and go to /admin/blazer"
    puts "    2. Run '#{queries.first.name}'"
    puts "       Expect both schools, with 6 and 3 teachers affected respectively, and"
    puts "       1 teacher already registered at the linked school for Waternoose"
    puts "    3. Run '#{queries.last.name}'"
    puts "       Expect a row per teacher, Needleman Smitty showing 'period deleted"
    puts "       before it started', and Randall Boggs flagged as registered at the"
    puts "       linked school since"
    puts
  end
end

# Rake loads every task file into one namespace, and a bare `def` here would
# define these on Object for the whole process.
module Scenario4277
module_function

  def close_school!(gias_school)
    return if GIAS::Reconciliation::Close.close!(gias_school)

    raise "#{gias_school.name} (#{gias_school.urn}) cannot be closed — has it already been processed?"
  end

  def link_to_successor!(gias_school, successor, link_type)
    GIAS::SchoolLink.create!(
      urn: gias_school.urn,
      link_urn: successor.urn,
      link_type:,
      link_date: gias_school.closed_on
    )
  end

  def create_gias_school!(urn:, name:, status:, closed_on: nil)
    GIAS::School.create!(
      urn:,
      name:,
      status:,
      closed_on:,
      type_name: "Community school",
      local_authority_code: 201,
      in_england: true,
      section_41_approved: false,
      eligible: true
    ).tap { School.create!(urn:) }
  end

  def create_teacher!(trn, first_name, last_name)
    Teacher.create!(
      trn:,
      trs_first_name: first_name,
      trs_last_name: last_name,
      trs_qts_awarded_on: Date.new(2022, 1, 1),
      trs_induction_status: "InProgress"
    )
  end
end
