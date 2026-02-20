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

# Add headers to the teachers.csv so we can select by "TRN" rather than position 0
# trn,first_name,last_name,extension_length,extension_length_unit,induction_status
#
#
#
# Export TRNs of Exempt teachers
# $ xan search Exempt tmp/import/teachers.csv | xan select trn > tmp/import/exempt_trns.csv
# 1006852
#
# Export TRNs of Failed (only) teachers
# $ xan search Failed tmp/import/teachers.csv | xan search -v FailedInWales | xan select trn > tmp/import/failed_trns.csv
# 407
#
# Export TRNs of FailedInWales teachers
# $ xan search FailedInWales tmp/import/teachers.csv | xan select trn > tmp/import/failed_in_wales_trns.csv
# 8
#
# number of inductions by TRS status
#
# Filter inductions by Exempt teachers who also have start date and count
# $ xan join --left trn tmp/import/exempt_trns.csv trn tmp/import/inductionperiods.csv | xan filter started_on | xan count
# 13184
#
# Filter inductions by Failed teachers who also have start date and count
# $ xan join --left trn tmp/import/failed_trns.csv trn tmp/import/inductionperiods.csv | xan filter started_on | xan count
# 524
#
# Filter inductions by FailedInWales teachers who also have start date and count
# $ xan join --left trn tmp/import/failed_in_wales_trns.csv trn tmp/import/inductionperiods.csv | xan filter started_on | xan count
# 2
#
#
#
#
