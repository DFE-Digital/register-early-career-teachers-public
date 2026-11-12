---
title: Lead providers
---

Lead providers work with delivery partners to deliver training to early career teachers (ECTs) and their mentors. DfE funds this training for eligible participants, as described in the [guidance on provider-led training](https://www.gov.uk/guidance/set-up-and-manage-the-early-career-teacher-entitlement#use-an-approved-lead-provider-provider-led).

Lead providers use the service's API to:

* confirm which schools and delivery partners they work with
* access information about the ECTs and mentors they train
* report changes to training
* declare that training has taken place and track the resulting payments

Schools register participants and choose their training arrangements using the web interface. Lead providers confirm partnerships, arrange participant training with their delivery partners and report on training engagement through the API. These responsibilities give the DfE the information needed to pay providers.

## Accessing the API

Lead providers are issued with API tokens which they use to authenticate requests. Access is associated with the provider rather than an individual user account. Missing or invalid tokens receive a `401 Unauthorized` response.

The DfE issues tokens on request through [Galaxkey](https://www.galaxkey.com/). Tokens do not expire automatically, but the DfE can revoke them. Changes reported through the API are attributed to the lead provider in the service's audit events.

Access is limited according to the provider's relationship with the data. For example, providers can see their own partnerships and participants, and relevant declaration history when a participant has trained with another provider. They can only void their own declarations.

The sandbox allows providers to test integrations without changing live participant or payment records. See the [connection guidance](https://www.register-early-career-teachers.education.gov.uk/api/docs/training/guidance/guidance-for-lead-providers/connect-to-rect-api) for obtaining and using tokens, and the internal [API token documentation](https://github.com/DFE-Digital/register-early-career-teachers-public/blob/main/documentation/api-tokens.md) for environment-specific information.

## Finding schools

`GET /schools` and `GET /schools/{id}` help providers identify schools to work with and understand their training arrangements for a particular cohort. A cohort filter is required.

The API includes schools currently eligible for funded training, together with schools that already have a partnership for the requested cohort. Keeping existing partnerships visible allows providers to maintain their records if a school's eligibility changes.

Schools choose training arrangements for each participant, however the API summarises those choices at the school level:

* `induction_programme_choice` summarises the school's training programme choices for the cohort
* `in_partnership` indicates whether the school has any confirmed partnership for that cohort, **including with another provider**
* `expression_of_interest` indicates whether the school has selected the requesting provider for a participant in that cohort, **including training linked to a confirmed partnership**

A school can express interest in more than one provider. Where training has been linked to a confirmed partnership, `expression_of_interest` remains true even if participants subsequently leave. A partnership without any linked training does not by itself set this flag.

On the schools endpoints, induction tutor contact details are shared when `expression_of_interest` is true for the requesting provider and cohort. Partnership responses also expose these contact details.

The [funding eligibility policy](https://www.gov.uk/guidance/eligibility-and-funding-for-the-early-career-teacher-entitlement#eligible-schools-and-establishments) explains which establishments can receive funded training. 

See [Schools in Swagger](https://www.register-early-career-teachers.education.gov.uk/api/docs/v3#/Schools) for the school-level fields and filters.

## Finding delivery partners

`GET /delivery-partners` and `GET /delivery-partners/{id}` return delivery partners associated with the requesting provider's framework agreements. Providers use these records to identify the delivery partner when creating or updating a school partnership.

Delivery partner arrangements are specific to a contract period. A delivery partner must be recorded as working with the lead provider for that period before they can be used in a school partnership. This ensures that training is assigned to an agreed delivery arrangement.

Providers can read these arrangements through the API but DfE maintains them.  

See [Delivery Partners in Swagger](https://www.register-early-career-teachers.education.gov.uk/api/docs/v3#/Delivery%20Partners).

## Confirming school partnerships

A school partnership records an agreement between a school, a lead provider and a delivery partner for a contract period, exposed as a cohort in the API. It connects participants' training to the organisations delivering it.

Providers can view their partnerships using `GET /partnerships` and `GET /partnerships/{id}`, and confirm new agreements using `POST /partnerships`. This supports the [requirement for both schools and providers to tell DfE about their partnership](https://www.gov.uk/guidance/set-up-and-manage-the-early-career-teacher-entitlement#tell-dfe-if-the-school-is-using-a-lead-provider).

### Creating partnerships

A partnership can be created before the school registers participants or expresses interest in the provider. Creating it does not assign every participant at the school to that provider - **the school chooses the provider for each participant**.

Different lead providers can partner with the same school in the same cohort. Where a school needs multiple delivery partners under the same lead provider, DfE adds the additional partnerships manually.

Schools can carry forward an existing partnership when registering participants in a later cohort. Providers can retrieve these partnerships without submitting them again.

### Correcting partnerships

`PUT /partnerships/{id}` corrects the delivery partner on an existing partnership. The replacement must be associated with the provider for the same contract period, and the correction must not duplicate an existing partnership.

Declarations retain the delivery partner recorded when they were created. Correcting a partnership therefore affects future declarations while preserving the history used for payments.

For a genuine change of delivery partner, providers contact DfE to create a new partnership record. Keeping a separate record allows the service to distinguish a change in training delivery from a correction.

Partnership responses include the school's induction tutor contact details and `participants_currently_training`. This count helps providers distinguish an agreement from active training: a partnership can remain in place with no participants currently training.

See [Partnerships in Swagger](https://www.register-early-career-teachers.education.gov.uk/api/docs/v3#/Partnerships).

## Viewing participants

`GET /participants` and `GET /participants/{id}` return ECTs and mentors whose provider-led training has been linked to the requesting provider through a confirmed school partnership. A school's selection of a provider alone does not give access to the participant.

Records remain visible after participants leave a school, change provider, move to school-led training or finish training. This continuity lets providers reconcile training and payment records. Records can be removed where a registration was incorrect or the participant never started.

### Funding eligibility and induction

The service exposes current participant eligibility separately from training progress. This flag alone does not determine declaration payment entitlement: the declaration funding check uses whether eligibility was ever established for the relevant course. The API reports current eligibility as follows:

* `eligible_for_funding: true` means the participant has become eligible for funding
* `eligible_for_funding: false` means the participant has become ineligible
* `eligible_for_funding: null` means eligibility has not yet been determined

The [eligibility and funding policy](https://www.gov.uk/guidance/eligibility-and-funding-for-the-early-career-teacher-entitlement#how-dfe-checks-the-eligibility-of-ects-and-mentors) explains DfE's checks, including the restriction on repeat funded mentor training.

### Participant and training statuses

The API exposes two statuses because a participant's relationship with a school or provider and their training engagement can differ:

* `participant_status` describes their position in the training arrangement, using dates, school-reported changes and completion information. Values include `joining`, `active`, `leaving` and `left`.
* `training_status` describes provider-reported deferral or withdrawal. Values are `active`, `deferred` and `withdrawn`.

A participant can have an active training status while their participant status is `left`. Providers need to consider both statuses, eligibility and completion dates when administering training.

See [Participants in Swagger](https://www.register-early-career-teachers.education.gov.uk/api/docs/v3#/Participants).

## Updating training

Lead providers can change a participant's schedule, defer or withdraw training, and resume training. Each action applies to the specified ECT or mentor course with that provider.

### Changing schedules

`PUT /participants/{id}/change-schedule` assigns a different training schedule and, optionally, cohort. Schedules define the training milestones against which declarations are checked, allowing for different start dates and training durations.

The schedule must exist for the target contract period and suit the course: ECTs cannot use replacement mentor schedules, and mentors cannot use reduced ECT schedules. Moving cohort requires a school partnership with the provider in the target contract period.

The service prevents changes for withdrawn participants, those who have left, and those with a later training period already arranged. Completed training normally prevents a schedule change, with an exception for moving an ECT to a reduced schedule. It also prevents changes that would invalidate existing declarations when updating a training period in place.

See the [schedules and milestones guidance](https://www.register-early-career-teachers.education.gov.uk/api/docs/training/guidance/guidance-for-lead-providers/schedules-and-milestones-guidance) for schedule allocation and contractual milestone guidance.

### Deferring or withdrawing training

`PUT /participants/{id}/defer` records a temporary pause; `PUT /participants/{id}/withdraw` records withdrawal. Both require an allowed reason and record when the provider reports the change.

These actions end the current training period, retaining its history for declarations and payments. They do not record an induction outcome or remove the participant from the provider's API records.

### Resuming training

`PUT /participants/{id}/resume` resumes deferred or withdrawn training by creating a new training period starting on the day of the request, using the previous partnership and schedule.

See [Participants in Swagger](https://www.register-early-career-teachers.education.gov.uk/api/docs/v3#/Participants) for these actions and their accepted values.

## Viewing school transfers

`GET /participants/transfers` and `GET /participants/{id}/transfers` expose school moves involving the requesting provider. Providers use these records to identify participants joining or leaving and maintain continuity of training.

Transfers are derived from school and training records. The API distinguishes a move to a new school with the same provider, a move involving a new provider, and a departure where the next training arrangement is unknown. Future-dated moves are shown as incomplete until the relevant dates have passed.

**A provider change within the same school does not constitute a school transfer**. Leaving after completing induction is also excluded when there is no subsequent school period. Providers read transfers through the API; schools report the underlying changes.

See [Transfers in Swagger](https://www.register-early-career-teachers.education.gov.uk/api/docs/v3#/Transfers).

## Viewing unfunded mentors

`GET /unfunded-mentors` and `GET /unfunded-mentors/{id}` give providers the identity and contact details of mentors assigned to their ECTs who do not have their own training record with that provider.

For example, a mentor may have trained with another provider but need access to the requesting provider's learning materials to support an ECT. Their identifier matches the ECT's `mentor_id`.

Mentors who have trained with the requesting provider remain available through the participants endpoints. They are not returned as unfunded mentors for that provider.

See [Unfunded mentors in Swagger](https://www.register-early-career-teachers.education.gov.uk/api/docs/v3#/Unfunded%20Mentors).

## Declaring training engagement

`POST /participant-declarations` records a provider's confirmation that an ECT or mentor has met the engagement requirements for a training milestone. Declarations provide the evidence on which DfE calculates output payments under the provider's contract. Contract management supplies the requirements and dates for each cohort.

Providers can retrieve declarations using `GET /participant-declarations` and `GET /participant-declarations/{id}`. Relevant declaration history from other providers is also visible for participants they have trained, helping them establish which milestones have already been claimed.

### Eligibility and payment

Accepting a declaration does not itself confirm that payment is due. A declaration starts as `submitted` in the API (internally `no_payment`) unless the participant's training is eligible for funding. Eligible declarations are assigned to an open output payment statement.

When an ECT becomes eligible after their induction is recorded, the service moves their submitted declarations to `eligible` and assigns payment statements. Providers do not need to resubmit them.

The service exposes these payment states (internally derived from the `payment_status` and `clawback_status`):

| State | Meaning |
| --- | --- |
| `submitted` | Recorded without a payment entitlement; this includes ECTs awaiting confirmation of eligibility. |
| `eligible` | Eligible for payment and assigned to a statement. |
| `payable` | The statement's cut-off date has passed and the declaration has progressed towards payment. |
| `paid` | DfE finance has marked the statement as paid. |
| `voided` | Cancelled before payment. |
| `awaiting-clawback` | Previously paid, with recovery now requested. |
| `clawed-back` | DfE finance has recorded recovery of the payment. |

### Voiding declarations and recovering payments

`PUT /participant-declarations/{id}/void` lets a provider retract its own declaration. Unpaid declarations become `voided`; paid declarations enter `awaiting-clawback` and are linked to a future output statement for recovery.

Voided or clawed-back declarations remain visible to preserve the payment audit trail.

See [Declarations in Swagger](https://www.register-early-career-teachers.education.gov.uk/api/docs/v3#/Declarations) for evidence requirements and request details, and the internal [state machine documentation](https://github.com/DFE-Digital/register-early-career-teachers-public/blob/main/documentation/state-machines.md) for implementation details of payment and clawback transitions.

## Viewing statements

`GET /statements` and `GET /statements/{id}` return the requesting provider's statement dates and payment status. Providers use them to understand payment cut-offs and reconcile declarations with payments.

The API does not expose the full financial breakdown provided in DfE's financial statements.

A statement starts as `open`. After its cut-off date, a background job marks it and its eligible declarations as `payable`. DfE finance subsequently marks the statement as `paid`. We expose if a statement has been `paid` through API, but not the other internal states.

See [Statements in Swagger](https://www.register-early-career-teachers.education.gov.uk/api/docs/v3#/Statements).

## Keeping provider records up to date

List endpoints are paginated. Where supported, cohort and `updated_since` filters let providers retrieve relevant changes without repeatedly downloading every record. Authenticated API requests are limited to 1,000 per token in a five-minute period.

The service maintains API timestamps and pre-calculated metadata so that information can be returned efficiently for the relevant provider and cohort. School-level summaries are derived from participant and partnership records. The internal [metadata documentation](https://github.com/DFE-Digital/register-early-career-teachers-public/blob/main/documentation/metadata.md) describes this implementation.

Incremental updates do not capture every change in a response. For example, participant status can change as a joining or leaving date passes without the record's timestamp changing. Providers should combine regular incremental polling with periodic full synchronisation, as described in the [data synchronisation guidance](https://www.register-early-career-teachers.education.gov.uk/api/docs/training/guidance/guidance-for-lead-providers/keeping-data-in-sync).

Invalid requests return errors identifying the affected fields so that providers can correct their data. Swagger documents each endpoint's responses; the internal [API validation errors](https://github.com/DFE-Digital/register-early-career-teachers-public/blob/main/documentation/api-errors.md) catalogue explains individual validation failures.
