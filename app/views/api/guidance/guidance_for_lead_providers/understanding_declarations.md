---
title: Understanding declarations
---

## What are declarations?

Declarations are formal submissions made by lead providers to confirm that a participant (an early career teacher or mentor) has engaged sufficiently with training during a specific period.

## What declarations do

Declarations:

- inform DfE training has taken place
- record participant progress across date milestones
- trigger payments from DfE to lead providers

The possible declaration types are:

- `started` – training began in a given period
- `retained-1` / `retained-2` / `retained-3` / `retained-4` – participant continued training through subsequent milestones
- `completed` – full programme finished
- `extended-1` / `extended-2` / `extended-3` – when an ECT's training continues beyond the standard schedule (not to be used for mentors)

Declaration types should ideally be submitted in the correct sequence for each participant, as outlined in the register early career teachers API specification. This also enables DfE to pay lead providers promptly.
For declarations relating to participants in pre-2025 cohorts, the declaration date must fall within the milestone dates set out in the contract management payment guidance. This requirement does not apply to post-2024 cohorts.
Successful requests will return a response body including updates to the declaration, which will become:

- `voided` if it had been `submitted`, `ineligible`, `eligible`, or `payable`
- `awaiting_clawback` if it had been `paid`

### The ordering of declarations across all cohorts for ECTs:

- `started`
- `retained-1`
- `retained-2`
- `retained-3`
- `retained-4`
- `completed`
- `extended-1`
- `extended-2`
- `extended-3`

### For mentors in the 2025 cohort onwards, the declaration types in order are:

- `started`
- `completed`

### For 2023 and 2024 mentors, the declaration types in order are:

- `started`
- `retained-1`
- `retained-2`
- `retained-3`
- `retained-4`
- `completed`

## How declarations are submitted

Declarations are submitted via the API, using endpoints like `POST participant-declarations`.

Each declaration includes:

- participant ID
- declaration type
- declaration date (aligned with what's outlined in the payment guidance)
- course identifier (indicates whether the declaration is for ECT or mentor training)
- evidence held (the type of evidence a lead provider holds to verify that a participant has engaged in training)

Declarations cannot be submitted or voided after a cohort has closed. Duplicate declarations cannot be submitted. If a duplicate is attempted, the API will return an error.

Providers can test they're able to submit declarations using [X-With-Server-Date](https://sandbox.register-early-career-teachers.education.gov.uk/api/guidance/guidance-for-lead-providers/how-to-test-the-api-effectively#test-declaration-submissions-using-x-with-server-date).

See the [Swagger documentation](https://sandbox.register-early-career-teachers.education.gov.uk/api/docs/v3#/Declarations) for full details of the declaration endpoints.

### How lead providers get paid for training participants

1. Participant attends training.
2. Lead provider records training milestone.
3. Lead provider submits declaration with 'retained-1' type via API.
4. API validates and links to relevant financial statement.
5. Declaration triggers payment (if valid).

Declarations cannot be submitted or voided after a cohort has closed. Duplicate declarations cannot be submitted. If a duplicate is attempted, the API will return an error.

If an ECT hasn't had their eligibility for funding confirmed, because their induction hasn't been recorded as starting by an appropriate body yet, you will be unable to receive payment for the associated declarations. They will be stuck in the submitted state.

They will be stuck in `submitted`. Appropriate bodies will not be able to submit inductions till after they have started, so expect them to stay in `submitted` until after the ECT should've officially started induction.

Once an `induction_start_date` appears over the API, they will be eligible for funding and any submitted declarations that are valid should move to `eligible`.

Providers can test they're able to submit declarations using [X-With-Server-Date](https://sandbox.register-early-career-teachers.education.gov.uk/api/guidance/guidance-for-lead-providers/how-to-test-the-api-effectively#test-declaration-submissions-using-x-with-server-date).

## Declaration states

Declaration states are defined by the `state` attribute.

A declaration's state value will reflect if and when DfE will pay providers for the training delivered.

| state | Definition | Action |
|-------|------------|--------|
| `submitted` | A declaration associated to a participant who has not yet been confirmed to be eligible for funding. An ECT's induction must be recorded as started by an appropriate body to make them eligible for funding | Providers can view and void submitted declarations |
| `eligible` | A declaration associated with a participant who has been confirmed to be eligible for funding | Providers can view and void eligible declarations |
| `payable` | A declaration that has been approved and is ready for payment by DfE | Providers can view and void payable declarations |
| `voided` | A declaration that has been retracted by a provider | Providers can only view voided declarations |
| `paid` | A declaration that has been paid for by DfE | Providers can view and void paid declarations |
| `awaiting_clawback` | A paid declaration that has since been voided by a provider | Providers can only view awaiting_clawback declarations |
| `clawed_back` | An awaiting_clawback declaration that has since had its value deducted from payment by DfE to a provider | Providers can only view clawed_back declarations |

When a declaration is voided, it will become:

- `voided` if it had been `submitted`, `ineligible`, `eligible`, or `payable`
- `awaiting_clawback` if it had been `paid`
## Evidence types

To see which evidence types are valid for each declaration type, check the [Swagger documentation](https://sandbox.register-early-career-teachers.education.gov.uk/api/docs/v3/) and refer to the relevant schema.

For pre-2025 cohorts, evidence is optional. If you do provide it, valid evidence types are:

- `training-event-attended`
- `self-study-material-completed`
- `other`

Evidence types for post-2024 cohorts are not compatible with pre-2025 cohorts. If a provider submits a declaration for a pre-2025 cohort using a post-2024 evidence type, the API will return a 422 error.
