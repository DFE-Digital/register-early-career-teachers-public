---
title: How cohort closures and changes work 
---

## Cohort closures

A cohort is closed when DfE stops funding training for that cohort year.

When a cohort is closed, it means:

- lead providers will no longer be able to receive payments for training participants assigned to that cohort
- DfE will stop generating output fee statements for the closed cohort
- we'll move partially trained early career teachers (ECTs) from the closed cohort to the 2024 cohort if there's evidence they require training
- lead providers can no longer void declarations for participants and no declarations should be submitted

## How we'll handle participants in closed cohorts

### Partially trained ECTs

We'll move ECTs to the 2024 cohort when there's evidence they require training.

This move will happen automatically when:

- a partially trained 2021 or 2022 ECT is registered at a new school
- a school changes the lead provider for a 2021 or 2022 ECT

In these cases, we’ll assign an extended September schedule (`extended-september`). This follows the same approach used in the manage training for ECTs service.

Once the participant is in the 2024 cohort and the correct partnership is in place, providers will be able to continue getting their details over the API and declare for them in line with the 2024 milestones.

If there's been a mistake and the ECT shouldn't have been moved to the 2024 cohort and is not continuing with training, you can move them back to their original closed cohort.

If an ECT doesn't meet one of the above criteria for an automatic move, they'll stay visible in `GET participants` for their original 2021 or 2022 cohort. You will not be able to submit declarations for them.

ECTs with no declarations submitted against them have been archived. Schools can re-register them at any point to start training.

### Partially trained mentors

We will not transfer mentors to the 2024 cohort because they're not eligible for further training. We'll mark them as completed and update their `mentor_funding_end_date`.

### ECTs and mentors with no eligible, payable, paid, awaiting_clawback or clawed_back declarations

These participants were archived in closed cohorts. Providers should retire their records. If they're re-registered in the later academic years, they'll have new IDs.

## Moving ECTs to the 2024 cohort

We'll move ECTs to the 2024 cohort when there's evidence they require training.

This move will happen automatically when:

- a partially trained 2021 or 2022 ECT is registered at a new school
- a school changes the lead provider for a 2021 or 2022 ECT

Once the participant is in the 2024 cohort and the correct partnership is in place, providers will be able to continue getting their details over the API and declare for them in line with the 2024 milestones.

If there's been a mistake and the ECT shouldn't have been moved to the 2024 cohort and is not continuing with training, you can move them back to their original closed cohort.

### If the ECT isn't moved automatically

If an ECT doesn't meet one of the above criteria for an automatic move, they'll stay visible in `GET participants` for their original 2021 or 2022 cohort. You will not be able to submit declarations for them.

If they had no declarations submitted against them, they'll be archived. Schools can re-register them at any point to start training.

## Identifying ECTs who we've moved to the 2024 cohort

To help providers identify these ECTs in the API, there's a field in the `GET participants` API endpoints named `cohort_changed_after_payments_frozen`.

For ECTs who've moved to the 2024 cohort, the field will have a `true` value in it.

When calling the `GET participants` endpoint, the ECT's cohort value will be `2024`. When calling the `GET participant-declarations` endpoint, the ECT will have historical declarations in their original cohort.

Providers should use the `cohort_changed_after_payments_frozen` field to identify the ECT.

We'll also assign these ECTs to the `ecf-extended-september` schedule. This allows providers to submit any required declarations for these ECTs.

## Identifying a participant's training needs

When providers receive a participant who has moved to the 2024 cohort from a closed cohort, we recommend they focus on:

- understanding how much training the participant has left
- when they last engaged with training
- where they were previously undertaking their training

Many of these participants will have experienced stop-start or interrupted training journeys, often due to deferrals or other changes.

There's no automated process to determine their continuation point or how much induction an ECT has left to serve, so it's important for providers to confirm this directly with the participant, the participant's school or their appropriate body.

## How to tell between 2022 and 2021 starters who've moved to the 2024 cohort

Providers can identify which cohort participants have moved from by taking the following steps:

1. Start by checking the `GET participants/ecf` endpoint for participants who've moved to the 2024 cohort after originally starting their training in 2021 or 2022. They're identified by the `cohort_changed_after_payments_frozen` attribute being `true`.

2. Then, using the `GET participant-declarations` or `GET participant-declarations/{id}` endpoint and filtering by `participant_id`, find the `statement_id`.

3. Finally, call `GET statements/{id}`. The `cohort` field in the response shows which cohort each declaration was originally made in.
