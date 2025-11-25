---
title: Update participant data
---

This guidance explains: 

* what participant data schools can update, and how these updates are displayed to providers via the API 
* what participant details providers can update, and how 

## Updates made by schools 

Schools can make the following updates: 

* participant names or contact details 
* start date corrections 
* record a mentor replacement 
* change the type of induction (either provider or school-led) an ECT is doing  
* move participants to a different lead provider 

## How providers can see updates made by schools    

When an update is received:  

* participant records are refreshed in the API 
* providers will be able to check for changes by querying the `participant_id_changes` filter on a participant's record 
* they should then update their records and check the participant’s current `eligible_for_funding` value before submitting declarations 
* corresponding funding and declaration logic is applied automatically  
* the `updated_since` filter will include the record for subsequent `GET /participants` queries 

## What lead providers can update 

Lead providers can use the API to notify DfE when a participant has: 

* deferred training 
* resumed training 
* withdrawn from training 
* changed training schedule 

These updates keep participant records aligned between systems and ensure correct funding calculations. 

For technical information, see the Swagger API documentation for [deferring](URL), [resuming](URL) and [withdrawing](/api/docs/v3#/Participants/put_api_v3_participants__id__withdraw) participants, and for [changing training schedules](URL).  
 
## When providers can defer or withdraw participants     

Providers can defer or withdraw participants as long as:  

* their `participant_status` isn’t `joining`  
* they've not already been deferred or withdrawn 

If a participant never started training, providers should contact us to request deletion of the participant’s record.  

## When providers can resume a participant’s training 

Providers can resume a participant when their `participant_status` is marked as `leaving` or `left`.    Providers cannot resume a participant if the `participant_status`was changed to `leaving` or `left` for any of the following reasons: 

* their old school has told us they’re leaving 
* their new school has told us they’re joining, with a different lead provider training them 
* they've changed to school-led training 
* they've changed to a different lead provider for training 

If the new school confirms the participant is starting with the same lead provider, their `participant_status` will revert to `joining` or `active`.  

## How to notify us if a participant’s changed from their standard training schedule 

We assign new ECTs and mentors to default standard schedules in September, January or April. 

View guidance on [how we assign participant schedules](/api/guidance/guidance-for-lead-providers/how-we-assign-participant-schedules) 

Providers must notify us of any other schedule via the `PUT /participants/{id}/change-schedule` endpoint. 

Successful requests will return a response body including updates to the `schedule_identifier` attribute. 

The API will reject a schedule change if any previously submitted `eligible`, `payable` or `paid` declarations have a `declaration_date` which does not align with the new schedule’s milestone dates. 

Where this occurs, providers should: 

1. Void the existing declarations (where `declaration_date` does not align with the new schedule). 
2. Change the participant’s training schedule. 
3. Resubmit backdated declarations (where `declaration_date` aligns with the new schedule). 

## How to assign a replacement mentor 

A new mentor can be assigned to an ECT part way through training. 

Providers must notify us of replacement mentors by updating their training schedule. 

<div class="govuk-inset-text">If a replacement mentor is already mentoring another ECT, the first ECT takes priority. In this case, the provider should not change the mentor’s schedule.</div> 

Providers must include a `schedule_identifier` reflecting when the replacement mentor starts: 

* `replacement-september` 
* `replacement-january` 
* `replacement-april` 

A replacement mentor’s schedule, and any associated declaration submissions, do not need to align with the ECT they are mentoring. 

## Recording completions 

We populate the `induction_end_date` on an ECT’s profile as soon as they complete their induction.  

Similarly, once providers submit a completed declaration for a mentor, the `mentor_funding_end_date` is populated. 

Providers should backdate declarations for participants who’ve completed their induction or mentor training and remove them from their active training lists, but they do not need to withdraw them. 
