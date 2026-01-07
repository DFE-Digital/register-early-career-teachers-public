appropriate_body_csv = Rails.root.join("tmp/import/appropriatebody.csv")
teachers_csv = Rails.root.join("tmp/import/teachers.csv")
induction_period_csv = Rails.root.join("tmp/import/inductionperiods.csv")
dfe_sign_in_mapping_csv = Rails.root.join("tmp/import/dfe-sign-in-mappings.csv")
admin_csv = Rails.root.join("tmp/import/admins.csv")
cutoff_csv = Rails.root.join("tmp/import/old-abs.csv")

AppropriateBodies::Importers::Importer.new(appropriate_body_csv:, teachers_csv:, induction_period_csv:, dfe_sign_in_mapping_csv:, admin_csv:, cutoff_csv:).import!
