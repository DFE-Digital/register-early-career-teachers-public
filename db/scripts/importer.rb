appropriate_body_csv = Rails.root.join("tmp/import/appropriatebody.csv")            # 537
teachers_csv = Rails.root.join("tmp/import/teachers.csv")                           # 1_799_170
induction_period_csv = Rails.root.join("tmp/import/inductionperiods.csv")           # 829_189
dfe_sign_in_mapping_csv = Rails.root.join("tmp/import/dfe-sign-in-mappings.csv")    # 86
dqt_csv = Rails.root.join("tmp/import/old-abs.csv") # 433

AppropriateBodies::Importers::Importer.new(
  appropriate_body_csv:,
  teachers_csv:,
  induction_period_csv:,
  dfe_sign_in_mapping_csv:,
  dqt_csv:
).import!

# https://teacher-cpd.design-history.education.gov.uk/ecf-v2/fixing-dqt-data/
#
# 1. How to rollback: filter teachers by "not ongoing" status in the CSV and select TRNs, script removal of all records by :teacher_id
# 2. How to check: export imported data to CSVs then copy from the pod for review
# 3. How to validate: insert_all is protected by db unique keys
# 4. How to review: ran against snapshot locally
# 5. How to upload: copy via kubectl to a single worker pod
# 6. How to run: rails runner the script on the pod
