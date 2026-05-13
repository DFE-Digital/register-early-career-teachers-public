---
title: How to prepare for the 2026 to 2027 academic year
sidebar_position: 1
---

Guidance on what we plan to do for current and existing cohorts, and what this means for lead providers.

## The 2023 cohort is not closing

We are not closing the 2023 cohort until all cohorts related to ECF close. This is different to how we closed 2021 and 2022 cohorts.

We expect to close the 2023 cohort in 2027. We’ll let lead providers know when we’ve confirmed the date.

### What this means for lead providers

Lead providers should continue to do what they’ve been doing for the 2023 cohort. They need to make sure that they can manage 4 open cohorts at one time.

If lead providers continue to train and make declarations for partially trained ECTs or mentors, they need to make sure participants are on an extended schedule. Lead provers will need to move participants onto an extended schedule if they are not already. 

If lead providers are assigned 2023 participants, they’ll need to partner with the school for the 2023 cohort to be able to train and declare against them.

If lead providers are unable to offer training to participants, they need to tell the school to partner with another provider. 

## We are not archiving participants in the 2023 cohort

We are not archiving any participants, even if they have no declarations.

### What this means for lead providers

If ECTs or mentors get re-registered, lead providers will need to move their cohort and schedule if participants had not started training legitimately before. 

If an ECT or mentor was first registered in the 2023 cohort, did not engage with training and is subsequently assigned to a new ECT, lead providers will need to update their cohort and schedule to reflect they are starting training in the 2026 cohort.

## We are not closing off partially trained mentors in the 2023 cohort

Partially trained mentors, if they continue to be trained, can be declared against in the 2023 cohort.

### What this means for lead providers

Lead providers must make sure any mentors that they continue to train are:

* put on an extended schedule
* compliant with the fully trained mentor guidance and any additional guidance they’ve been given by their contract manager 

Lead providers should check with contract managers if they’re uncertain.

## Mentor completion dates and additional training

Usually, a mentor’s eligibility for additional training will be determined if they have a completion date or not.

### Some mentors with completion dates are available for additional training

Some mentor data might be returned with a populated mentor funding end date (`mentor_funding_end_date`) and reason (`mentor_ineligible_for_funding_reason`) in GET participant responses. These mentors could still be eligible for additional funded training. 

This is because as part of closing the 2021 and 2022 cohorts in the digital service, all mentors without a completion reason had to be marked with the started-not-completed reason.

Where a mentor has this completion reason, lead providers must check their own records to confirm that the mentor had not previously been assigned to an ECT for 2 or more years in the past before they were last withdrawn. 

A 2021 or 2022 cohort mentor is considered fully trained and not eligible for further training if either they:

* had more than 2 years access to funded training while assigned to one or more ECTs
* were never withdrawn during that time

If a mentor has had fewer than 2 years access to funded training before they were last withdrawn, they may be eligible for additional training. This is dependent on the number of paid declarations.

#### Mentors with more than one declaration paid out against them

These mentors are eligible for a maximum of 2 additional declarations, if this will not exceed 6 paid declarations in total. 

This training will be paid from their ECF cohort. Further declarations cannot be submitted over the API and must be submitted manually to contract managers.

#### Mentors with no or just one declaration paid out against them

These mentors are eligible to restart training under the early career teacher training programme (ECTPM) contract. These mentors will need moving to the relevant ECTPM cohort. 

ECTPM declarations must be submitted manually to contract managers if there is a 2021 or 2022 started or completed declaration in existence. Otherwise, their declarations can be submitted over the API.

### Some mentors without completion dates are not eligible for additional training

Some mentor data might be returned with an unpopulated mentor funding end date (`mentor_funding_end_date`) and reason (`mentor_ineligible_for_funding_reason`) in GET participant responses. However, they could still be ineligible for additional funded training.

This is because it’s possible 2023 and 2024 cohort mentors without a completion reason may still have met one of the contract management definitions of being a fully trained mentor.

If a lead provider can confirm that a mentor has had more than 2 years access to funded training without having been withdrawn, they are considered fully trained and not eligible for further training.

Lead providers should check with contract managers if they’re uncertain.  

## 2026 cohort opening

We’ll email lead providers by the end of June to let them know registration is open. We expect it to open on 15 June. Any participants starting their training from 1 June 2026 will be assigned to the cohort.

To ensure that participants are not put onto the wrong schedule or cohort, we’ll block participant registrations, including transfers, between 1 June and 14 June. 

Lead providers can self-serve using the API to change a registered participant’s cohort to 2025 if needed. 

The 2026 opening will be like previous openings but with some differences. 

### Partnerships

In the new service, schools can select a lead provider if they do not have one or where there’s been a change to the provider. If they do this, an ‘expression of interest’ (EOI) will be generated and set to ‘true’, and school induction tutor details populated.

These details will be available to the selected lead provider over the API with GET schools. This means that lead providers can set up training more efficiently.  

Lead providers will be able to create partnerships as soon as the cohort opens, regardless of if the school has registered any ECTs or mentors with them yet. 

Schools can also reuse partnerships from any previous cohort where a partnership was in place. Lead providers will not need to create new ones. 

Lead providers can find out more about partnerships in our [create view and update partnership guidance](https://www.register-early-career-teachers.education.gov.uk/api/guidance/guidance-for-lead-providers/create-view-and-update-partnerships) 

### Sharing data with delivery partners

Delivery partners no longer have direct access to DfE ECT and mentor data. Lead providers will now be responsible for sharing data with delivery partners for all cohorts.

### Prepare systems for 2026

We encourage lead providers to make sure their systems and processes will work with the 2026 cohort. This will mean that they’ll be able to receive and submit data for these cohorts, for example on GET participants and GET declarations.

## Support

Lead providers can use [resources for release](https://register-ects-service-manual.education.gov.uk/resources-for-release/).

Lead providers can direct schools to email continuing-professional-development@digital.education.gov.uk if they have problems with the service.
