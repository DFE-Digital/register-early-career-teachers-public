# Generate date that is invalid bypassing validations in order to test data triage
appropriate_body_period = AppropriateBodyPeriod.first

teacher = Teacher.new(
  trn: "9999999",
  trs_first_name: "Demo",
  trs_last_name: "Invalid",
  trs_qts_awarded_on: Date.new(2025, 1, 1),
  mentor_became_ineligible_for_funding_on: Date.current - 30,
  mentor_became_ineligible_for_funding_reason: nil,
  trs_induction_status: "Invalid",                      # unrecognised status
  trs_induction_start_date: nil,                        # missing
  trs_induction_completed_date: Date.new(1999, 1, 1)    # differs from induction data predates QTS
)
teacher.save!(validate: false)

teacher.reload

ranges = [
  [Date.new(2023, 9, 1), Date.new(2024, 8, 31)],  # predates QTS overlaps next
  [Date.new(2024, 1, 1), Date.new(2024, 12, 31)], # overlaps next
  [Date.new(2024, 6, 1), Date.new(2099, 5, 31)]   # future date
]

periods = ranges.map do |started_on, finished_on|
  InductionPeriod.new(
    teacher:,
    appropriate_body_period:,
    induction_programme: "fip",
    started_on:,
    finished_on:
  ).tap do |ip|
    ip.save!(validate: false)
    ip.reload
  end
end

print_seed_info(
  "Seeded invalid teacher TRN #{teacher.trn} + #{periods.size} invalid inductions",
  indent: 2
)
