print_seed_info("Bulk uploads", blank_lines_before: 1, colour: :green)

umber = AppropriateBodyPeriod.find_by!(name: "Umber Teaching School Hub")

claim_data = [
  { trn: "3000100", date_of_birth: "1990-03-15", training_programme: "provider-led", started_on: "2025-01-30" },
  { trn: "3000101", date_of_birth: "1988-07-22", training_programme: "provider-led", started_on: "2025-02-01" },
  { trn: "3000102", date_of_birth: "1995-11-05", training_programme: "school-led", started_on: "2025-01-15" },
  { trn: "9999999", date_of_birth: "2005-01-01", training_programme: "provider-led", started_on: "2025-03-01" },
]

claim_batch = PendingInductionSubmissionBatch.create!(
  appropriate_body_period: umber,
  batch_type: "claim",
  batch_status: "completed",
  data: claim_data,
  uploaded_count: 4,
  processed_count: 4,
  errored_count: 1,
  released_count: 0,
  passed_count: 0,
  claimed_count: 3
)

claimed_submissions = [
  { trn: "3000100", trs_first_name: "Alice",  trs_last_name: "Smith",   date_of_birth: Date.new(1990, 3, 15) },
  { trn: "3000101", trs_first_name: "Bob",    trs_last_name: "Johnson", date_of_birth: Date.new(1988, 7, 22) },
  { trn: "3000102", trs_first_name: "Claire", trs_last_name: "Davies",  date_of_birth: Date.new(1995, 11, 5) },
]

claimed_submissions.each do |attrs|
  PendingInductionSubmission.create!(
    pending_induction_submission_batch: claim_batch,
    appropriate_body_period: umber,
    trs_induction_status: "None",
    trs_qts_awarded_on: 2.years.ago.to_date,
    induction_programme: "fip",
    training_programme: "provider_led",
    started_on: 1.year.ago.to_date,
    delete_at: 1.day.ago,
    **attrs
  )
end

PendingInductionSubmission.create!(
  pending_induction_submission_batch: claim_batch,
  appropriate_body_period: umber,
  trn: "9999999",
  date_of_birth: Date.new(2005, 1, 1),
  error_messages: ["TRN not found"]
)

Event.create!(
  event_type: "bulk_upload_started",
  heading: "Bulk upload started",
  happened_at: 2.hours.ago,
  pending_induction_submission_batch: claim_batch,
  author_email: "freddy@example.com",
  author_name: "Fred Jones",
  author_type: :appropriate_body_user
)

Event.create!(
  event_type: "bulk_upload_completed",
  heading: "Bulk upload completed",
  happened_at: 1.hour.ago,
  pending_induction_submission_batch: claim_batch,
  author_email: "freddy@example.com",
  author_name: "Fred Jones",
  author_type: :appropriate_body_user
)

print_seed_info("Claim batch for Umber Teaching School Hub (4 rows, 1 error)", indent: 2)
