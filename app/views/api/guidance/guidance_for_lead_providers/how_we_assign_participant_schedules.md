---
title: How we assign participant schedules
---

We pay lead providers based on agreed contractual schedules and training delivery criteria. Payments are proportional to the time providers support their participants.

We'll default new ECTs and mentors to standard schedules in September, January or April. 

Providers will need to review schedules and update them if they’re not correct. 

## Standard schedule assignment for ECTs 

We’ll assign a standard September, January or April schedule based on the earliest start date we have for the participant. This will either be the date the ECT started at their school or the date they were registered for training (if later).  

ECTs cannot start training until they’re registered. If registration happens late, we’ll place them on the next term’s schedule. 

| Date range | Schedule assigned |  
| ------------ | ------------- |   
| 1 June to 31 October | `standard-september` |   
| 1 November to 28/29 February | `standard-january` | 
| 1 March to 31 May | `standard-april` | 

We’ll use the same date boundaries for mentors, based on when they start training. 

## Extended schedules 

We’ll reassign partially trained ECTs from closed cohorts to an active cohort if there’s evidence they require continued training.    

In these cases, we’ll assign an extended September schedule (`extended_september`). 

This follows the same approach used in the ‘Manage training for ECTs’ service API. 

## Replacement mentor schedules 

If a school registers a replacement mentor for an ECT, we’ll assign a replacement mentor schedule that matches the term they start training. 

| Date range | Schedule assigned |  
| ------------ | ------------- |   
| 1 June to 31 October | `replacement-september` |   
| 1 November to 28/29 February | `replacement-january` | 
| 1 March to 31 May | `replacement-april` | 

It’ll be up to providers to check these automatically assigned replacement schedules. If a replacement mentor later supports an ECT new to training before the term ends, providers must update the mentor’s schedule to a standard one. 

## Reviewing and correcting schedules 

These default schedules are designed to reduce the number of manual updates required, but providers are still responsible for checking and correcting them. 

Once a schedule has been assigned, it will not change automatically if a participant moves to another school. 

Providers must: 

* review all automatically assigned schedules
* update any schedules that are not appropriate
* confirm that every participant is on the correct schedule for their circumstances 
