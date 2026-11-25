# Lead provider mentorship statuses

`LeadProviderMentorshipStatus` stores a `status`, `reason` and timestamps for a
lead provider and mentorship period. The pair is unique.

Both fields are required by model validations and database `NOT NULL` constraints.
They are calculated automatically before validation on creation, so callers only
need to supply the mentorship period and lead provider.

A provider is linked to a mentorship when its ECT at school period has training
with that provider through a confirmed school partnership. Historical training
periods count; expressions of interest and mentor-only links do not.

## Calculation

`LeadProviderMentorshipStatus#refresh!` calculates and persists `status` and `reason`.
The following rules are evaluated in order:

| Condition | Status | Reason |
| --- | --- | --- |
| The mentorship's `finished_on` is on or before today | `no-access-required` | `mentorship-expired` |
| All of the mentee training periods for the lead provider have finished | `no-access-required` | `ect-finished-training-with-provider` |
| The mentor's `mentor_became_ineligible_for_funding_on` is populated | `access-and-support-only` | `completed-training` |
| The mentor has current or future training with this provider | `available-to-train` | `available-to-train` |
| The mentor has current or future training, but none confirmed with this provider | `access-and-support-only` | `mentor-training-elsewhere` |
| The mentor has training periods, all of which have finished | `access-and-support-only` | `mentor-not-currently-training` |
| The mentor has no training periods | `access-and-support-only` | `no-known-training` |

For the ECT rule, only confirmed training with the polling provider belonging to
the mentorship's ECT at school period is considered. At least one matching
training period is required, and all must have a `finished_on` on or before today.

For the mentor rules, only training periods belonging to the mentorship's mentor
at school period are considered. Training ending today is still current;
training with no end date or a future end date also counts. An
expression-of-interest-only training period does not count as confirmed training
with the polling provider.

## Automatic refresh

Model callbacks call `MentorshipPeriods::MentorshipStatus#refresh!` in the same
transaction when a mentorship is created or its `finished_on` changes, when
associated ECT or mentor training is created or its `finished_on`, school
partnership or expression of interest changes, and when the mentor's funding
ineligibility date changes (including being cleared).

Training changes refresh all mentorships for that at school period. Funding
changes refresh the mentor's mentorships across all schools.

## Nightly refresh

`MentorshipPeriods::RefreshStatusesJob` runs daily at 00:05 UTC in production,
sandbox, staging and review. It processes existing `MentorshipPeriod` records in
batches, calling `MentorshipPeriods::MentorshipStatus#refresh!` to create missing
provider/status rows and refresh existing ones.

`updated_at` advances only when `status` or `reason` changes, so unchanged
statuses do not appear as updates merely because the job ran. The mentorship
period's own timestamps are not touched.

The job does not create mentorship periods. Missing provider/status rows are
created only for providers linked through confirmed mentee training. The nightly
refresh also handles date-driven changes that occur without a record being saved.
