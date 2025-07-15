# ECF version 1 released: 1st September 2021
ECF_ROLLOUT_DATE = Date.new(2021, 9, 1).freeze

# Introduction of ECT statutory induction: 1st September 1999
STATUTORY_INDUCTION_ROLLOUT_DATE = Date.new(1999, 9, 1).freeze

# ECT at school periods, Induction periods, Pending induction submissions
TRAINING_PROGRAMME = {
  provider_led: 'Provider-led',
  school_led: 'School-led'
}.freeze

# Old types (induction periods and pending induction submissions) to be deprecated
INDUCTION_PROGRAMMES = {
  fip: 'Full induction programme',          # (provider-led)
  cip: 'Core induction programme',          # (school-led)
  diy: 'School-based induction programme',  # (school-led)
}.freeze

# bidirectional mapper for persisted values in training programmes (school_led cannot be reversed)
PROGRAMME_MAPPER = {
  "fip" => "provider_led",
  "provider_led" => "fip",
  "cip" => "school_led",
  "diy" => "school_led",
  'school_led' => 'unknown'
}.freeze

# ECT at school periods
WORKING_PATTERNS = {
  part_time: 'Part-time',
  full_time: 'Full-time'
}.freeze

# Induction periods and pending induction submissions
INDUCTION_OUTCOMES = {
  pass: 'Passed',
  fail: 'Failed'
}.freeze
