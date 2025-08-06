# CSV processing for multiple Appropriate Body claims and outcomes

The "bulk upload" feature allows ABs to upload a CSV file and process multiple ECT claims
or process multiple ECT outcomes and releases more efficiently.

### Entity relationship diagram

```mermaid
erDiagram

  AppropriateBody {
    string name
    enum body_type
  }

  PendingInductionSubmissionBatch {
    enum batch_type "claim, action"
    enum batch_status "pending, processing, processed, completing, completed, failed"
    string error_message
    string file_name
    integer file_size
    string file_type
    jsonb data "[]"
    integer uploaded_count
    integer processed_count
    integer errored_count
    integer released_count
    integer failed_count
    integer passed_count
    integer claimed_count
  }

  PendingInductionSubmission {
    string trn
    date date_of_birth
    date started_on
    date finished_on
    float number_of_terms
    enum induction_programme "fip, cip, diy"
    enum training_programme "school_led, provider_led"
    enum outcome "pass, fail"
    string error_messages
    datetime delete_at
  }

  Teacher {
    string trn
  }

  InductionPeriod {
    date started_on
    date finished_on
    float number_of_terms
    enum induction_programme "fip, cip, diy"
    enum training_programme "school_led, provider_led"
    enum outcome "pass, fail"
  }

  PendingInductionSubmissionBatch |o--|{ PendingInductionSubmission : has_many
  PendingInductionSubmissionBatch }o--|| AppropriateBody : belongs_to
  PendingInductionSubmission }o--|| AppropriateBody : belongs_to
  InductionPeriod }o--|| AppropriateBody : belongs_to
  InductionPeriod }o--|| Teacher : belongs_to
```

## Existing manual journey

- The manual journeys gather data in draft form before making changes to important data in the service.
- Drafted and validated `PendingInductionSubmission`s would be turned into an `InductionPeriod` or `Teacher` change
- `PendingInductionSubmission`s are ephemeral and deleted the next day if they are successful

## Technical approach

- The initial spike saved files to disk and attempted to convert each row immediately.
- We wanted to co-opt the existing manual journey models and services where possible to minimise duplication.
- A file is converted into submissions similar to the manual journey and grouped with a parent record `PendingInductionSubmissionBatch`, unlike submissions these are retained.
- Decided against storing files and adding ActiveStorage for lower overhead and easier deployment, instead we process data in memory and store as JSON in the database.
- Data is processed asynchronously in two stages to support the "Check your answers" pattern.
- Validations needed to behave slightly differently to the manual journey with extra formatting validations and different messages, surfaced with a particular hierarchy.
- The `PendingInductionSubmissionBatch` record is either a "claim" or "action" type, with the latter resulting in pass or fail outcomes, or releases.
- A batch transitions through various states, with "processing" potentially taking minutes to complete for large files and the user experience uses dynamic page updates to track progress.
- Any batch that contains rows that could not be actioned retains its submissions and data which are combined for the user to download as a CSV with actionable errors.

## Implementation details

- The bulk feature is powered by SolidQueue jobs delegating to services and Hotwire for dynamic page updates.
- ECT checks use both TRN and DoB. The database submission TRN field has constraints so extra guard logic was necessary.
- The only file format we accept is CSV, and the files we generate use quotations around cells. There are two templates, one for each batch type. All dates must use the ISO8601 standard. The maximum number of rows we allow is 1k.
- CSV rows are wrapped in `Data` objects for processing which enforce the templates and encapsulate the common formatting logic.
- Counts of outcomes and failures are tallied before CSV data which contains PII is redacted and submissions pruned as usual
- Batch jobs use inheritance to defer to a dedicated service class which have their own queue. The queue is higher priority like the mailers because it impacts the user experience.
- The event records were updated to associate to batches and it is through events we are able to determine which inductions were done via a bulk upload.

## Considerations

- During the initial development of bulk outcomes we also fast-tracked bulk claims to facilitate manual testing.
- Prior to release we surfaced database changes to enable better testing and these became the first draft of an admin console.
- Upon release the feature helped flag that worker queue config and pod resources needed attention.
- Initial usage highlighted that using the CYA approach needed further consideration as external changes could invalidate rows.
