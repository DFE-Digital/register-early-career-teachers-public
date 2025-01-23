require 'optparse'

namespace :appropriate_body do
  desc "Import Appropriate Body data from the old AB Portal"
  task import: :environment do
    appropriate_bodies_csv = 'db/samples/appropriate-body-portal/appropriate-body.csv'
    teachers_csv = 'db/samples/appropriate-body-portal/teachers.csv'
    induction_periods_csv = 'db/samples/appropriate-body-portal/induction-periods.csv'

    files = {}

    opts = OptionParser.new
    opts.banner = "Usage: rake appropriate_body:import --appropriate-body /tmp/ab.csv --teacher /tmp/teacher.csv --induction-period /tmp/ip.csv"
    opts.on("-a", "--appropriate-body ARG", String) { |val| files[:appropriate_bodies_csv] = val }
    opts.on("-t", "--teacher ARG", String) { |val| files[:teachers_csv] = val }
    opts.on("-i", "--induction-period ARG", String) { |val| files[:induction_periods_csv] = val }
    args = opts.order!(ARGV) {}
    opts.parse!(args)

    appropriate_bodies_csv = files[:appropriate_bodies_csv] if files[:appropriate_bodies_csv]
    teachers_csv = files[:teachers_csv] if files[:teachers_csv]
    induction_periods_csv = files[:induction_periods_csv] if files[:induction_periods_csv]

    logger = Logger.new($stdout)
    logger.info "Checking files exist"

    logger.info "Importing Appropriate Body records from #{appropriate_bodies_csv}"
    imported_abs = AppropriateBodies::Importers::AppropriateBodyImporter.new(appropriate_bodies_csv).import
    logger.info "  #{imported_abs} Appropriate Body records imported ✅"

    logger.info "Importing Teacher records from #{teachers_csv}"
    imported_teachers, total_teachers = AppropriateBodies::Importers::TeacherImporter.new(teachers_csv).import
    logger.info "  #{imported_teachers} Teacher records imported out of #{total_teachers} ✅"

    logger.info "Importing Induction Periods from #{induction_periods_csv}"
    imported_induction_periods, total_induction_periods = AppropriateBodies::Importers::InductionPeriodImporter.new(induction_periods_csv).import
    logger.info "  #{imported_induction_periods} Induction period records imported out of #{total_induction_periods} ✅"
  end
end
