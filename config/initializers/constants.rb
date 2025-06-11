# ECF version 1 released: 1st September 2021
ECF_ROLLOUT_DATE = Date.new(2021, 9, 1).freeze

# Introduction of ECT statutory induction: 1st September 1999
STATUTORY_INDUCTION_ROLLOUT_DATE = Date.new(1999, 9, 1).freeze

# ECT at school periods
TRAINING_PROGRAMME = {
  provider_led: 'Provider-led',
  school_led: 'School-led'
}.freeze

# ECT at school periods
WORKING_PATTERNS = {
  part_time: 'Part-time',
  full_time: 'Full-time'
}.freeze

# Induction periods and pending induction submissions
INDUCTION_PROGRAMMES = {
  fip: 'Full induction programme',
  cip: 'Core induction programme',
  diy: 'School-based induction programme'
}.freeze

# Induction periods and pending induction submissions
INDUCTION_OUTCOMES = {
  pass: 'Passed',
  fail: 'Failed'
}.freeze
