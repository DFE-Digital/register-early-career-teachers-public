#------------------------------------------------------------------------------
# SELECT t.table_schema,
#        t.table_name
# FROM information_schema.tables t
# WHERE t.table_type = 'BASE TABLE'
#   AND t.table_schema NOT IN ('information_schema', 'pg_catalog')
#   AND NOT EXISTS (
#     SELECT 1
#     FROM information_schema.table_constraints tc
#     WHERE tc.constraint_type = 'PRIMARY KEY'
#       AND tc.table_schema = t.table_schema
#       AND tc.table_name = t.table_name
#   )
# ORDER BY t.table_schema, t.table_name;

#------------------------------------------------------------------------------
# ALTER TABLE teachers ADD PRIMARY KEY (id);
# ALTER TABLE induction_periods ADD PRIMARY KEY (id);
# ALTER TABLE induction_extensions ADD PRIMARY KEY (id);
# ALTER TABLE events ADD PRIMARY KEY (id);

#------------------------------------------------------------------------------
# SELECT setval('teachers_id_seq', (SELECT COALESCE(MAX(id), 0) FROM teachers));
# SELECT setval('induction_periods_id_seq', (SELECT COALESCE(MAX(id), 0) FROM induction_periods));
# SELECT setval('induction_extensions_id_seq', (SELECT COALESCE(MAX(id), 0) FROM induction_extensions));
# SELECT setval('events_id_seq', (SELECT COALESCE(MAX(id), 0) FROM events));

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

# 1309 teachers with inductions to be imported are already in the prod database (2 with inductions)

# │
# │register-early-career-teachers(dev)> Teacher.count
# │=> 101381
# │register-early-career-teachers(dev)> AppropriateBodyPeriod.count
# │=> 534
# │register-early-career-teachers(dev)> InductionPeriod.count
# │=> 117056
# │register-early-career-teachers(dev)> InductionExtension.count
# │=> 1391
# │register-early-career-teachers(dev)> Event.count
# │=> 492082

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
# ➜ xan headers tmp/import/teachers.csv
# 0   trn
# 1   first_name
# 2   last_name
# 3   extension_length
# 4   extension_length_unit
# 5   induction_status
#
# xan filter 'len(trim(trn)) == 7' tmp/import/teachers.csv | xan count
# 1_799_171
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
