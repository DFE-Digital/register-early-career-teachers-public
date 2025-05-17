---
title: Lead provider API
---

# Partnerships documentation

This documentation provides a comprehensive guide to how partnerships work in ECF.

A partnership is a formal arrangement between the following entities for a given academic year/cohort:

- Lead provider (national organisations approved by the DfE to design and deliver ECF-based training),
- Delivery partner (often local teaching school hubs, multi-academy trusts, or schools that work directly with early career teachers (ECTs) and mentors), and
- School (participating educational institutions in England that employ ECTs)

A partnership enables a lead provider to perform several key functions within the DfE’s early careers framework (ECF) digital service and API. Essentially, it gives the lead provider the authority and technical access to manage and deliver training to early career teachers (ECTs) at specific schools, through a designated delivery partner.

## Contents

[Setting up partnerships](#setting-up-partnerships)

[Forming and managing partnerships](#forming-and-managing-partnerships)

[Viewing partnership information](#viewing-partnership-information)

[Clarifying terms](#clarifying-terms)

[Induction records](#induction-records)

## Setting up partnerships

### Cohort creation and opening registration (developer)

A cohort for the upcoming academic year is created in the system to enable registration to open (we follow [this process](https://dfedigital.atlassian.net.mcas.ms/wiki/spaces/CPD/pages/3883663396/Create+new+ECF+cohort) for creating a new cohort). It involves running the `CreateNewECFCohort` import service, providing it with CSVs for:

- The new cohort
- The lead providers that are active for the new cohort
- Contracts
- Schedules
- Statements

### Setting up delivery partners for a cohort (administrator)

Admins can sign in and navigate to `Suppliers -> Add a new delivery partner` in order to set up delivery partners for the new cohort.

When adding a delivery partner they are asked to specify the lead providers and cohorts that the delivery partner is associated with. Existing delivery partners can be updated to support lead providers in a newly added cohort.

This form is responsible for creating the `ProviderRelationship` entities in the database.

### Obtaining schools for a partnership (lead provider)

A lead provider is able to retrieve a list of schools that they can partner with via the API `GET /api/v3/schools/ecf`. The lead provider **must** specify a cohort in the request. The response will include all schools that are:

- Eligible (open, in England and either an eligible establishment type or section 41 approved).
- Not CIP only.

It will also include schools that have an existing partnership for the provided cohort.

In addition, lead providers can also filter by:

- The `urn` of a particular school.
- An `updated_since`.

The endpoint supports sorting and pagination.

See [the API documentation](https://manage-training-for-early-career-teachers.education.gov.uk/api-reference/reference-v3.html#api-v3-schools-ecf-get) for detailed examples.

### Obtaining delivery partners for a partnership (lead provider)

A lead provider is able to retrieve a list of delivery partners that they can partner with via the API `GET /api/v3/delivery-partners`. The response will include all delivery partners that were connected to the lead provider when setting up the delivery partners for a cohort (it does this by looking at the `ProviderRelationship` entities).

Lead providers can also filter by a specific cohort(s).

The endpoint supports sorting and pagination.

See [the API documentation](https://manage-training-for-early-career-teachers.education.gov.uk/api-reference/reference-v3.html#api-v3-delivery-partners-get) for detailed examples.

## Forming and managing partnerships

### Confirming induction programme type (school induction tutor (SIT))

When registration opens schools are able to begin adding ECTs and selecting how they want to deliver training by specifying their induction programme type:

- Provider-led
- School-led
- Not yet known
- No ECTs this year

### Creating a partnership (lead provider)

Lead providers are able to form a partnership with a school and a delivery partner via the API `POST /api/v3/partnerships/ecf`. They must provide the:

- `cohort` for the partnership (e.g. `2024`).
- `school_id` that they want to partner with (e.g. `24b61d1c-ad95-4000-aee0-afbdd542294a`).
- `delivery_partner_id` that they want to partner with (e.g. `db2fbf67-b7b7-454f-a1b7-0020411e2314`).

See [the API documentation](https://manage-training-for-early-career-teachers.education.gov.uk/api-reference/reference-v3.html#api-v3-partnerships-ecf-post) for detailed examples.

Prior to creating a partnership we will perform validation to ensure:

- The cohort, school and delivery partner all exist in the system.
- The school is not CIP only (which would trigger a funding error).
- The school is eligible (open, in England and either an eligible establishment type or section 41 approved).
- The school is not already partnered with the lead provider for the given cohort.
- The school is not already partnered with a different lead provider for the given cohort.
- The school has confirmed that they will delivery DfE funded training for the given cohort.
- The delivery partner has a `ProviderRelationship` created for the lead provider (see above).

If the above validation is satisfied, the partnership will be created with the lead provider (it will **not** be a relationship type partnership). 

A challenge deadline will be set on the partnership to give time for the school to challenge the declared partnership. The date will be the **maximum** of either:

- The default challenge window of 14 days from creation of the partnership.
- The `academic_year_start_date` + 14 days, if set on the `cohort`.

There are a number of possible error messages we return to lead providers if they fail to provide an appropriate request body when creating a partnership:

- Cohort not specified: `Enter a '#/cohort'.`
- Cohort not found: `The '#/cohort' you have entered is invalid. Check cohort details and try again.`
- School not specified: `Enter a '#/school_id'.`
- School not found: `The '#/school_id' you have entered is invalid. Check school details and try again. Contact the DfE for support if you are unable to find the '#/school_id'.`
- School is CIP only: `The school you have entered has not registered to deliver DfE-funded training. Contact the school for more information.`
- School is not eligible: `The school you have entered is currently ineligible for DfE funding. Contact the school for more information.`
- Partnership already exists with school and lead provider: `You are already in a confirmed partnership with this school for the entered cohort.`
- Partnership already exists with school and different lead provider: `Another provider is in a confirmed partnership with the school for the cohort you entered. Contact the school for more information.`
- School has not specified funding type for academic year: `The school you have entered has not yet confirmed they will deliver DfE-funded training. Contact the school for more information.`
- Lead provider not specified: `Enter a '#/lead_provider_id'.`
- Lead provider not found: `Enter a valid '#/lead_provider_id'.`
- Delivery partner not specified: `Enter a '#/delivery_partner_id'.`
- Delivery partner not found: `The '#/delivery_partner_id' you have entered is invalid. Check delivery partner details and try again.`
- Delivery partner not setup for cohort: `The entered delivery partner is not recognised to be working in partnership with you for the given cohort. Contact the DfE for more information.`

### Updating a partnership (lead provider)

A partnership can be updated by lead providers via the API `PUT /api/v3/partnerships/ecf/{id}`. They must provide the:

- `delivery_partner_id` they want to change to.

A number of possible error messages exist when updating a partnership:

- Delivery partner not specified: `Enter a '#/delivery_partner_id'.`
- Delivery partner not found: `The '#/delivery_partner_id' you have entered is invalid. Check delivery partner details and try again.`
- Delivery partner not setup for cohort: `The entered delivery partner is not recognised to be working in partnership with you for the given cohort. Contact the DfE for more information.`
- Partnership not found: `Enter a '#/partnership'.`
- Partnership is currently challenged: `Your update cannot be made as this partnership has been challenged by the school. If this partnership has been challenged in error, submit a new partnership confirmation using the endpoint POST /api/v3/partnerships/ecf.`
- Lead provider already has a **relationship** partnership with the school and delivery partner: `We are unable to process this request. You are already confirmed to be in partnership with the entered delivery partner. Contact the DfE for support.`

### What a partnership enables a lead provider to do

Once a partnership is formed and the induction records of participants have an associated lead provider, it will enable the lead providers to manage the school's participants via the API. They will be able to:

- Retrieve participants from the `GET /api/v{1,2,3}/participants/ecf` and `GET /api/v{1,2,3}/participants/ecf/{id}` endpoints.
- Perform actions on participants to change their training status via:
  - `PUT /api/v{1,2,3}/participants/ecf/{id}/defer`
  - `PUT /api/v{1,2,3}/participants/ecf/{id}/resume`
  - `PUT /api/v{1,2,3}/participants/ecf/{id}/withdraw`
- Submit declarations for participants using the `POST /api/v{1,2,3}/participant-declarations` endpoint.

They can also query their partnerships via `GET /api/v3/partnerships/ecf` and `GET /api/v3/partnerships/ecf/{id}` and manage/update them via `PUT /api/v3/partnerships/ecf/{id}`.

### On-boarding a participant (SIT)

When a SIT on-boards a participant - after choosing the appropriate body and assigning a mentor - they are prompted to link the participant with a partnership. On completing the rest of the on-boarding steps the `EarlyCareerTeachers::Create` service is called to instantiate a new participant in the system. From here, the `Induction::Enrol` service is called with the relevant induction programme for the chosen provider (or the default if that was specified). The participant's training status is set to `active` and a new induction record is created linking them to the relevant induction programme (and therefore lead provider and delivery partner).

## Viewing partnership information

### Viewing partnership records (administrator)

Administrators are able to view and search partnership records by navigating to the `Schools` tab. Once here, they can select a school and then the `Cohorts` tab lists the partnership information for each cohort, including:

- Training programme
- Appropriate body
- Delivery partner
- Lead provider

It is also possible to set up and change the induction programme for a school/cohort here as well as challenge partnerships.

### Viewing partnership records (finance)

Finance users are able to view partnership information in two places.

On both the `Search participant data -> Enter search terms -> Select participant` page they can view:

- Trianing programme
- Lead provider

On the `View finance statements -> Select lead provider -> Download declarations CSV` export they can view:

- Delivery partner
- Lead provider

## Clarifying terms

In ECF we have the notion of both **partnerships** and **relationship partnerships**.

A **partnership** describes an _active_ relationship between a lead provider, school and delivery partner for a given cohort. 

A **relationship partnership** is created when a participant transfers to a school that does not have a partnership with the lead provider/delivery partner that the participant is currently training with. In order to support the participant (and to get around the limitation of one 'active' partnership per school) we use the notion of a relationship partnership. This enables us to surface the participant appropriately in the API, even though they do not have a formal partnership arranged with the school.

A **challenged** partnership is where a school has submitted a challenge to a partnership created by a lead provider. Once challenged, the lead provider will not be able to update that partnership. Participants in a challenged partnership are excluded from the `GET /api/v{1,2,3}/participants/ecf` and `GET /api/v{1,2,3}/participants/ecf/{id}` endpoints.

## Induction records

When a partnership is created the `Induction::ChangePartnership` is called to migrate participants into the partnership.

It will find all the full induction programmes for the school and cohort of the partnership that do not currently have a partnership set and we update the induction programme partnership to the newly created one.

It calls `Induction::MigrateParticipantsToNewProgramme` to migrate all the participants of these induction programmes (that do not have partnerships) to the new/up to date induction programme assigned to the partnership we created. This involves populating the lead provider on all the participant's induction records.
