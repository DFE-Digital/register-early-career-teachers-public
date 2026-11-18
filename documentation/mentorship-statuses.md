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
| The mentor's `mentor_became_ineligible_for_funding_on` is populated | `access-and-support-only` | `completed-training` |
| The mentor has current or future training with this provider | `available-to-train` | `available-to-train` |
| The mentor has current or future training, but none confirmed with this provider | `access-and-support-only` | `mentor-training-elsewhere` |
| The mentor has training periods, all of which have finished | `access-and-support-only` | `mentor-not-currently-training` |
| The mentor has no training periods | `access-and-support-only` | `no-known-training` |

Only training periods belonging to the mentorship's mentor at school period are
considered. Training ending today is still current; training with no end date or
a future end date also counts. An expression-of-interest-only training period
does not count as confirmed training with the polling provider.

## Nightly refresh

`MentorshipPeriods::RefreshStatusesJob` runs daily at 00:05 UTC in production,
sandbox, staging and review. It processes existing `LeadProviderMentorshipStatus`
rows in batches, calling each model's `refresh!` method to recalculate and
persist both fields.

`updated_at` advances only when `status` or `reason` changes, so unchanged
statuses do not appear as updates merely because the job ran. The mentorship
period's own timestamps are not touched.

The job does not create mentorship periods or missing provider/status rows.
Creation of provider/status rows is handled separately; changes to underlying
data are reflected when the refresh next runs.
