---
title: API data states
---

## What this page covers  

In the 'Register early career teachers’ API, participants and declarations move through defined states. These reflect their training journey and whether funding is due. Understanding each state is essential for submitting the right data at the right time. 

Use this page to: 

* understand the different states a participant or declaration can be in
* learn how these states affect data submission and funding
* handle transitions correctly in lead provider systems 

## Participant states 

Participant states are defined by the `training_status` attribute. 

A participant's `training_status` highlights data entered **by lead providers** via the API. It then determines what onward actions providers can take via the API. Providers should also consider supplementary data available via the API, including the `participant_status`. 

A participant’s `training_status` value will determine whether a lead provider can: 

* update their details
* submit a declaration 

| Training status | Definition | Action | 
| -------- | -------- | -------- | 
| `active`     | Participants currently in training     | Lead providers can update participant data and submit declarations for `active` participants     | 
| `deferred`     | Participants who have deferred training     | Lead providers **cannot** update participant data or submit declarations for `deferred` participants. Lead providers must [notify DfE when the participant resumes training](add link to ‘notify DfE a participant has resumed training' guidance)    | 
| `withdrawn`     | Participants who have withdrawn from training     | Lead providers **cannot** update participant data for `withdrawn` participants. Lead providers can **only** submit declarations for `withdrawn` participants if the `declaration_date` is backdated to before the `withdrawal_date`    | 

### Participant status

The `participant_status` attribute highlights information given **by school induction tutors** via the 'Register early career teachers’ service. 

Values include `active`, `joining`, `leaving`, `left` and `withdrawn`, and will update according to the associated transfer or withdrawal dates induction tutors have given. For example, the `participant_status` will change from `leaving` to `left` after the date an induction tutor has given for when a participant is leaving their school. 

We have occasionally seen cases where this information has been inaccurate because an induction tutor made an error when entering participant data. 

## Declaration states 

Declaration states are defined by the `state` attribute. 

Lead providers must submit declarations to confirm a participant has engaged in training within a given milestone period. A declaration’s `state` value will reflect if and when DfE will pay lead providers for the training delivered. 

| State | Definition | Action | 
| -------- | -------- | -------- | 
| `submitted`     | A declaration associated with to a participant who has not yet been confirmed to be eligible for funding    | Providers can view and void `submitted` declarations    | 
| `eligible`     | A declaration associated with a participant who has been confirmed to be eligible for funding     | Providers can view and void `eligible` declarations    | 
| `ineligible`     | A declaration associated with 1) a participant who is not eligible for funding 2) a duplicate submission for a given participant    | Providers can view and void `ineligible` declarations     | 
| `payable`     | A declaration that has been approved and is ready for payment by DfE    | Providers can view and void `payable` declarations     | 
| `voided`     | A declaration that has been retracted by a provider    | Providers can **only** view `voided` declarations   | 
| `paid`     | A declaration that has been paid for by DfE    | Providers can view and void `paid` declarations     | 
| `awaiting_clawback`     | A `paid` declaration that has since been voided by a provider    | Providers can **only** view `awaiting_clawback` declarations     | 
| `clawed_back`     | An `awaiting_clawback` declaration that has since had its value deducted from payment by DfE to a provider     | Providers can **only** view `clawed_back` declarations     | 

## Best practice 

Lead providers should:  

* match their data to the current state of each participant
* monitor declaration responses for issues
* use sandbox testing to see how state transitions behave before working in live 
