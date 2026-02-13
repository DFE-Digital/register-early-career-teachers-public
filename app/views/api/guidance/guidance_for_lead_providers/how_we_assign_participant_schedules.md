---
title: How we assign participant schedules
---

## Purpose and scope of this guidance

This guidance explains how schedules and milestone dates operate within the Register Early Career Teachers service.

Schedules and milestone dates are contractually determined and owned by the Department for Education (DfE). This guidance should be read alongside the Payment Guidance issued by contract management, which remains the authoritative source for payment dates, liability, and contractual requirements.

Access to training materials should not necessarily be tied to a participant's cohort or schedule. For example, a mentor may have finished training in 2023 but still need to be given access to learning materials to support ECTs they are mentoring in 2025.

The purpose of this document is to:

* explain how schedules and milestones are assigned and represented in the API
* support providers in understanding when and how schedules may need to be updated

## Key concepts

This table defines terms used throughout this guidance. For other contractual terms and definitions, refer to the guidance issued by contract management.

| Concept | Definition |
| ------- | ---------- |
| Milestone | Contractual retention periods during which providers must submit relevant declarations evidencing training delivery and participant retention |
| Milestone dates | The deadline date a valid declaration can be made for a given milestone in order for DfE to be liable to make a payment the following month. Milestone dates are dependent on the participant's schedule |
| Milestone period | The period of time between the milestone start date and deadline date. This period is also referred to as a declaration window |
| Milestone validation | The API's process to validate declarations submitted by providers for participants in standard training schedules |
| Output payment | The payment amount that DfE publishes on a finance statement, which is based on valid declarations |
| Payment date | The date that DfE aims to process frozen statements by, so that payments can be made |
| Schedule | Schedules are timed sequences of expected milestone and payment points.<br><br>These are set when new early career teachers or mentors are registered, based on when they are starting at a school, when they're registered, and if they're a replacement mentor.<br><br>They are then updated and corrected by lead providers via the API.<br>Schedules give DfE information about how participants are being trained, and can also set the milestone periods when lead providers can submit declarations for |
| Extended schedule | A non-standard training schedule for participants who expect to complete the induction over a period greater than 2 years.<br><br>Examples include part-time ECTs, or ECTs whose induction period is extended by their appropriate body. Mentors can also be assigned extended schedules |
| Reduced schedule | A non-standard training schedule for ECTs who expect to complete the induction over a period less than 2 years. Examples include those with previous experience |
| Replacement schedule | A non-standard training schedule for mentors that are replacing a previous mentor for an ECT that is part way through their training. The mentor must be completely new to provider-led mentor training |
| Standard schedule | The default training schedule for participants completing a standard 2 year induction, starting in September, January or April |

## Standard schedules and dates

The service will assign a standard September, January or April schedule based on the date the ECT started at their school, or the date they were registered for training (if later).

For mentors, the logic to assign schedules will relate to:

* when they've been registered for training by the school
* if they're identified by the service as a replacement mentor

Providers will need to review schedules and update them if they're not correct.

ECTs should not start training until they're registered. If registration happens late, we'll place them on the next schedule assignment.

| Date range | Schedule assigned |
| ---------- | ----------------- |
| 1 June to 31 October | `standard-september` |
| 1 November to 28 or 29 February | `standard-january` |
| 1 March to 31 May | `standard-april` |

We'll use the same date boundaries for mentors, based on when they're first registered as an ECT's mentor.

For participants who started their training on or before 31 December 2024, refer to the guidance provided by contract management for those cohorts.

## Non-standard schedules and dates

### Replacement mentor schedules

If a school registers a replacement mentor for an ECT, we'll assign a replacement mentor schedule based on when they're first registered as the ECT's mentor (`replacement-september`, `replacement-january` or `replacement-april`).

It will be up to providers to check these automatically assigned replacement schedules. If a newly assigned replacement mentor later supports a new ECT doing provider-led training as their first mentor before the end of the next milestone period, and before the mentor's first started declaration is due, providers must update the mentor's schedule to a standard one.

### Extended schedules

We'll reassign partially trained ECTs from closed cohorts to an active cohort if there's evidence that they require further training.

In these cases, we'll assign an extended September schedule (`extended_september`).

This follows the same approach used in the Manage training for ECTs service.

## Reviewing and correcting schedules

These default schedules are designed to reduce the number of manual updates required, but providers are still responsible for checking and correcting them.

Once a schedule has been assigned, it will not change automatically if a participant moves to another school.

In most cases, the schedule suffix (September, January or April), is determined by when the participant first started training, not by when they joined a new school or provider.

For example, if a participant who started on a standard-september schedule transfers to a new school after one term, they will usually remain on the same schedule. Providers should not change the schedule suffix simply because the participant joined them part way through the academic year.

The same principle applies to participants who defer and later resume training. While their circumstances may mean they need to move to an extended schedule, the original start point of their training still determines the schedule suffix.

Providers must:

* review all automatically assigned schedules
* update any schedules that are not appropriate
* confirm that every participant is on the correct schedule for their circumstances

## Milestone and payment date guidance

DfE pays lead providers based on agreed contractual schedules and training delivery criteria. Payments are proportional to the time providers support their participants.

Output payments are based on valid declarations submitted by the declaration deadline for each milestone. Milestone dates correspond to each participant's schedule.

Contract management circulates milestone dates and payment guidance to lead providers.

For example, a 2025 cohort ECT who started on 1 September 2025 and is completing training over 2 academic years would be on the standard September schedule.

`"schedule_identifier": "standard-september"`

| Milestone | Start date | Declaration deadline | Declaration type | Payment date |
| --------- | ---------- | -------------------- | ---------------- | ------------ |
| Participant Start | 1 Jun 2025 | 31 Oct 2025<br><br>31 Dec 2025 | started<br><br>started | 30 Nov 2025<br><br>31 Jan 2026 |
| Retention Point 1 | 1 Jan 2026 | 31 Mar 2026 | retained-1 | 30 Apr 2026 |
| Retention Point 2 | 1 Apr 2026 | 31 Jul 2026 | retained-2 | 31 Aug 2026 |
| Retention Point 3 | 1 Aug 2026 | 31 Dec 2026 | retained-3 | 31 Jan 2027 |
| Retention Point 4 | 1 Jan 2027 | 31 Mar 2027 | retained-4 | 30 Apr 2027 |
| Participant Completion | 1 Apr 2027 | 31 Jul 2027 | completed | 31 Aug 2027 |
