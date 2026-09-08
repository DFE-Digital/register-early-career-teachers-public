# Backfill teacher records + rejection events for teachers whose DQT induction
# data was too bad to import. Consumes the amended rejected-induction-period CSV.
rejected_csv = Rails.root.join("tmp/import/dqt_induction_period_parser_rejected.csv")

AppropriateBodies::Importers::RejectedTeacherImporter.new(
  data_csv: rejected_csv
).import!
