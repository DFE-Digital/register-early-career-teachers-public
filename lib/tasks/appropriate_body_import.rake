namespace :appropriate_body do
  desc "Import Appropriate Body data from the old AB Portal"
  task import: :environment do
    logger = Logger.new($stdout)
    logger.info "Checking files exist"

    logger.info "Importing Appropriate Body records"
    imported_abs = AppropriateBodies::Importers::AppropriateBodyImporter.new.import
    logger.info "  #{imported_abs} Appropriate Body records imported ✅"

    logger.info "Importing Teacher records"
    imported_teachers, total_teachers = AppropriateBodies::Importers::TeacherImporter.new.import
    logger.info "  #{imported_teachers} Teacher records imported out of #{total_teachers} ✅"

    logger.info "Importing Induction Periods"
    imported_induction_periods, total_induction_periods = AppropriateBodies::Importers::InductionPeriodImporter.new.import
    logger.info "  #{imported_induction_periods} Induction period records imported out of #{total_induction_periods} ✅"
  end
end
