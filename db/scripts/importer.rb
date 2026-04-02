# For dev/test import valid ABs. Skip for prod where they already exist.
if AppropriateBodyPeriod.count.zero?
  dfe_sign_in_mapping_csv = Rails.root.join("tmp/import/dfe-sign-in-mappings.csv")
  appropriate_body_csv = Rails.root.join("tmp/import/appropriatebody.csv")

  AppropriateBodies::Importers::AppropriateBodyImporter.new(
    data_csv: appropriate_body_csv,
    dfe_sign_in_mapping_csv:
  ).import!
end

teachers_csv = Rails.root.join("tmp/import/teachers.csv")
induction_period_csv = Rails.root.join("tmp/import/inductionperiods.csv")

AppropriateBodies::Importers::TeacherInductionImporter.new(
  teachers_csv:,
  induction_period_csv:
).import!
