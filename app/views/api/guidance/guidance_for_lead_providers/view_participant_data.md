---
title: View participant data
---

Lead providers can use the `GET /participants` endpoints to view early career teachers (ECTs) and mentors currently or previously linked to their partnerships. 
 
This data helps providers monitor eligibility, progress, and training milestones. 
 
For detailed technical specifications, see the [Swagger API documentation for participants endpoints](/api/docs/v3#/Participants).  

Read our guidance on [how we assign participant schedules](/api/guidance/guidance-for-lead-providers/how-we-assign-participant-schedules).  

## Which ECTs or mentors are surfaced in the `GET /participants` endpoints 

Lead providers will see any participants from a school where both: 

1. The school has stated at some point they’re the lead provider for that participant.  
2. The lead provider has either submitted a partnership or it’s been rolled over from a previous cohort by the school. 

This includes cases, if the partnership exists, where: 

* the school later changes lead provider for that participant
* the school later changes programme type to school-led for that participant
* the participant later leaves the school 

This should mean participants will not ‘disappear’ in the `GET /participants` endpoints except in cases where they shouldn't have been visible in the first place. For example, if they were incorrectly registered or never started at a school. 

## What providers can use participant data for 

Providers can use this data to check whether participants: 

* have started their induction (`overall_induction_start_date`), and are therefore eligible for funding 
* have transferred to or from a school they’re partnered with 
* have (if they’re ECTs) an assigned unfunded mentor 
* have (if they’re ECTs) completed induction

Participants may use different email addresses across training programmes, but providers will only see the email linked to the specific course registration associated with them. 

## Participant visibility and continuity 

Providers will continue to see participants if they’ve ever had a confirmed partnership with them, even if: 
 
* their school later changes
* their lead provider or delivery partner changes
* their induction programme type (ECF-based or school-based) changes 

This ensures providers can keep accurate records.

## Retrieve multiple participants 

Providers can use the `GET /participants` endpoint to retrieve data for multiple participants.  

The following table shows the filters providers can use within this endpoint. 

| Filter | Description | Example | 
| ------------ | ------------- | ------------- | 
| `filter[cohort]` | Restrict results to a specific cohort |`filter[cohort]=2025` | 
| `filter[cohort]` | Return results for multiple cohorts | `filter[cohort]=2023,2024,2025` | 
| `filter[updated_since]` | Return only records updated after a specific date | `filter[updated_since]=2025-09-01T00:00:00Z` | 

## Retrieve a single participant 
 
Providers can use the `GET /participants/{id}` endpoint to view individual records. 

The following table explains the key participant fields. 

| Field | Description |  
| ------------ | ------------- |  
| `eligible_for_funding` | For ECTs, becomes `true` once the participant’s induction is confirmed by an appropriate body. It will never revert to `false` | 
| `overall_induction_start_date` | The date an ECT officially began statutory induction as submitted by their appropriate body | 
| `induction_end_date` | The date an ECT completed (passed or failed) their induction | 
| `trn` | The participant’s teacher reference number. If a TRN is missing, it means the participant’s registration predates validation, and we have no matching TRN in our records | 

## Participant statuses 

The API uses two different status fields to describe a participant’s journey in the participant endpoints: 

* `training_status`, set by providers through the API. It determines what actions providers can take, such as updating data or submitting declarations
* `participant_status`, shows if a participant is still engaging with training at their school. It moves to `left` whenever the school or lead provider indicates the participant is no longer training with the current lead provider, even if they remain at the school 

Together, these statuses give both providers and schools a shared view of a participant’s training progress. 

The following table explains what the training status fields mean. 

| `training_status` | Definition | Notes | 
| ------------ | ------------- | ------------- | 
| `active` | Participant is currently in training | Update participant data and submit declarations | 
| `deferred` | Participant has paused training | Cannot update participant data. Can submit declarations. Providers must notify us when the participant resumes | 
| `withdrawn` | Participant has left training | Cannot update participant data. Can only submit backdated declarations if `declaration_date` is before `withdrawal_date` | 

The following table explains what the participant status fields mean. 

| `participant_status` | Definition | 
| ------------ | ------------- | 
| `joining` | ECT is due to join the school. Will update to `active` on the same day as the school’s reported start date for the ECT. Also applies to mentors in transfer cases where a joining date exists | 
| `active` | Participant is currently at the school | 
| `leaving` | Participant is due to leave the school. Will update to left after the leaving date passes | 
| `left` | Participant has left a school, been reassigned to a different lead provider, had their programme type changed to `school-led`, or been withdrawn or deferred by a lead provider | 
 
### Example of how statuses for participants can differ 

The API shows a participant as `training_status = active` because they're still completing training. 

At the same time, the participant’s school informs us that the participant is leaving with a leaving date set for the end of term. This triggers the `participant_status` to change to `leaving`. 

In this case, the participant is still active in training, but their school has flagged that they're due to leave soon. Once the leaving date passes, the `participant_status` will update to `left`. 

The provider will need to update the training record when they're certain the participant is withdrawn from training and not training with them as the lead provider at their new school.

## Participant ID changes 

If a participant was registered more than once, they may have duplicate IDs. 
 
When this happens, we: 
 
* retire one participant ID
* associate all records under the remaining ID 

Providers can track this in the `participant_id_changes` nested structure, which includes: 
 
* `from_participant_id`
* `to_participant_id`
* `changed_at` (ISO timestamp) 
