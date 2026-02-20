appropriate_body_csv = Rails.root.join("tmp/import/appropriatebody.csv")            # 537
teachers_csv = Rails.root.join("tmp/import/teachers.csv")                           # 1_799_170
induction_period_csv = Rails.root.join("tmp/import/inductionperiods.csv")           # 829_189
dfe_sign_in_mapping_csv = Rails.root.join("tmp/import/dfe-sign-in-mappings.csv")    # 86
admin_csv = Rails.root.join("tmp/import/admins.csv")                                # 30
cutoff_csv = Rails.root.join("tmp/import/old-abs.csv")                              # 433

# AppropriateBodies::Importers::Importer.new(
#   appropriate_body_csv:,
#   teachers_csv:,
#   induction_period_csv:,
#   dfe_sign_in_mapping_csv:,
#   admin_csv:,
#   cutoff_csv:
# ).import!

# https://teacher-cpd.design-history.education.gov.uk/ecf-v2/fixing-dqt-data/

# AppropriateBody.count     # 532           (5 omitted)
# InductionPeriod.count     # 87_271        (741_918 omitted)
# Teacher.count             # 75_082        (1_724_088 omitted)
# Event.count               # 126_485

# Need to import all inductions that have an end date before `18 Feb 2025`

# import_boundary = Date.parse("2025-02-18")

# InductionPeriod.count #=> 87271
# InductionPeriod.finished_before(import_boundary).count #=> 37643
# InductionPeriod.ongoing.count #=> 49628

# 49628 + 37643

ab_csv = CSV.read(appropriate_body_csv, headers: true)
csv_ab_names = ab_csv.map { |r| r["name"] }

current_ab_names = AppropriateBody.all.map(&:name)

debugger

csv_ab_names - current_ab_names
