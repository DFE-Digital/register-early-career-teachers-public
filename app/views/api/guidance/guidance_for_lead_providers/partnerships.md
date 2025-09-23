# Create, view and update partnerships 

## What are partnerships? 

Partnerships are agreements between schools, lead providers, and delivery partners to deliver training to early career teachers (ECTs) and mentors for a given cohort.  

## Partnerships process overview 

1. Cohort opens for registrations.
2. Schools register ECTs and mentors, choosing the programme type (`provider-led` or `school-led`) for each participant rather than making a schoolwide choice.
3. If the school chooses the `provider-led` option, they also tell us which lead provider will be training the participant. 
4. Lead providers find schools they want to partner with using `GET /schools` API endpoint. Schools that have selected them will show as `expression_of_interest = true`. 
5. Lead providers create partnerships via the `POST /partnerships` endpoint. They’ll then see any participants the school has assigned to them in `GET /participants`.

## Understanding partnerships in the API 

The API allows lead providers to confirm, view, and update these agreements so that participants are correctly assigned to training. 

Lead providers should always check for existing partnerships before creating a new one: 

* use `GET /partnerships` to see if a partnership already exists for the school and cohort
* use `GET /schools` to check which programme type the school has chosen and if it’s already partnered with another lead provider 

Submitting a duplicate partnership (same school, lead provider, and cohort) will return a `422 error`. 

Additional partnerships by different lead providers for the same school and cohort are now allowed. This reflects the fact that some schools work with multiple lead providers in a single cohort. 

### Partnership ID 

Each confirmed partnership has a unique identifier (`id`), returned in the `GET /partnerships` response. This `id` represents the agreement between a school, delivery partner, and lead provider for a given cohort. 

### How providers can find out if they’ve got participants training with them 

To see if a school has any ECTs training with them, we've introduced a new field, `participants_currently_training` in the `GET /partnerships` endpoint. This’ll show the number of ECTs or mentors currently training with a provider for that partnership. It’ll show `0` when: 

* no participants are registered for training with you by the school
* all participants complete training
* all participants are moved to another lead provider or school-led training
* there's any combination of the above 

Because schools now make changes at an individual participant level (for example, moving an ECT to a different provider) rather than challenging a school-wide partnership, we’ve removed challenge fields (`challenged_reason`, `challenged_at`, `status`) from partnership responses. 

### School induction tutor details 

Each partnership record shows one school induction tutor (name and email): 

* schools may have multiple users in the service, but only one induction tutor is surfaced to lead providers via the API 
* when schools first sign in after registration opens, they must provide the name and email of the induction tutor. That is what the API returns 

### When does a participant appear in a provider’s feed? 

Lead providers can check participant records using the `GET /participants` endpoint to see if a school is working with them: 

* if the participant appears, they’re the selected lead provider
* if the school later changes provider, the participant will remain in their feed with a `leaving` or `left` status (including moves to `school-led` or a different provider)
* if the participant does not appear, either the school has not selected them as the lead provider or their partnership with the school for that cohort has not been created or rolled over (or both) 

If providers believe a school has assigned the wrong provider to an ECT or mentor, they should ask the school to update the participant’s record in the service first. If they think they should be the provider, they can create a partnership to view the school induction tutor’s details. 

### Expression of interest records 

The `expression_of_interest` field in the `GET /schools` and `GET /schools/{id}` endpoints shows lead providers whether a school has any participants registered with them for that cohort. 

Schools now choose lead providers per participant, so this field reflects individual registrations, not a school-wide choice. A school may therefore show `expression_of_interest = true` for more than one lead provider. 

#### Example scenarios 

| Scenario |   `expression_of_interest` | 
| ------------ | ------------- |  
| School has registered at least one participant with the lead provider for the chosen cohort | `true`|  
| No participants registered with the lead provider | `false` |  
| No partnership for the cohort and the school reports all participants have left or are no longer training with the lead provider | Changes from `true` to `false` |  

#### Why `expression_of_interest` stays `true` after a partnership is confirmed 

Once a partnership is confirmed for a cohort, `expression_of_interest` remains `true` to show that the school is working with the lead provider for that cohort. 

If participants later leave, switch provider, or move to school-led, the flag stays `true`.  

## Find schools and delivery partners 

### Find schools 

Lead providers can use the `GET /schools` endpoint to find schools in a given cohort, check the school’s high-level programme status (`school-led` vs `provider-led`), and whether a partnership already exists.  

This will help providers find schools to work with, create or roll over partnerships, and avoid duplicate submissions. Since programme choice is now set per participant, this endpoint gives the school-level context needed to plan, while participant endpoints hold individual details. 

For detailed technical information, view the `GET /schools` [endpoint Swagger API documentation](/api/docs/v3#/Schools/get_api_v3_schools). 

#### What the API will show 
 
The API shows schools eligible for funded training in a given cohort or schools with existing partnerships which have become ineligible.  

#### What the API will not show 
 
The API will not show schools that are ineligible for funding in a given cohort. 
 
If a school’s eligibility changes from one cohort to the next, results will default according to the school’s latest eligibility. For example, if a school was eligible for funding in the 2025 cohort but becomes ineligible for funding in 2026, the API will not show the school in the 2026 cohort. 

### View a specific school 

The `GET /schools/{id}?filter[cohort]={year}` endpoint shows details including the programme type choice and confirmed partnerships for a single school in a given cohort.  

For detailed technical information, view the `GET /schools/{id}` [endpoint Swagger API documentation](/api/docs/v3#/Schools/get_api_v3_schools__id_). 

### Find delivery partners 

Lead providers can use the `GET /delivery-partners` endpoint to:

* get the required `delivery_partner_id` for creating or updating partnerships
* verify which delivery partners they can contractually work with in a given cohort

For detailed technical information, view the `GET /delivery-partners` [endpoint Swagger API documentation](/api/docs/v3#/Delivery%20Partners/get_api_v3_delivery_partners). 

### View a specific delivery partner 

Lead providers can use the `GET /delivery-partners/{id}` endpoint to see if a specific delivery partner is registered to deliver training for a cohort. 

For detailed technical information, view the `GET /delivery-partners/{id}` [endpoint Swagger API documentation](/api/docs/v3#/Delivery%20Partners/get_api_v3_delivery_partners__id_). 

## Create a partnership 

Lead providers can use the `POST /partnerships` endpoint to create partnerships. 

For detailed technical information, view the `POST /partnerships` [endpoint Swagger API documentation](/api/docs/v3#/Partnerships/post_api_v3_partnerships). 

### When lead providers can create a partnership 

Lead providers can create a partnership even if the school hasn’t registered participants. The only exceptions are when the cohort has not opened, or the school is doing `school-led` training. 
 
### Continuing into future cohorts 

During registration, induction tutors confirm whether to continue the partnership into the new cohort. They can carry forward the school’s most recent partnership, even if it’s from an earlier year. 

This reduces the need for lead providers to manually resubmit partnerships each cohort. 

## Multiple partnerships 

Previously, schools had a default partnership with a single lead provider for each cohort. 

We’ve changed this to reflect that some schools need to set up partnerships with more than one lead provider. 

The API now supports multiple partnerships for a school in the same cohort: 

* each lead provider can create one partnership per school per cohort
* different providers can have partnerships with the same school (for example, if an ECT transfers and stays with their previous provider)
* if a school needs several delivery partners under the same provider in the same cohort, lead providers must notify us (via Teams or email). We’ll then add these additional partnerships manually 

In the API: 

* `GET /partnerships` may return more than one partnership for the same school and cohort
* `in_partnership` will state `true` if any partnership exists and `false` if none exist

## View partnerships 

Lead providers can use the `GET /partnerships` endpoint to see all partnerships and the `GET /partnerships/{id}` endpoint to view individual partnerships.

For detailed technical information, view the `GET /partnerships` [endpoint Swagger API documentation](/api/docs/v3#/Partnerships/get_api_v3_partnerships) and `GET /partnerships/{id}` [endpoint Swagger API documentation](/api/docs/v3#/Partnerships/get_api_v3_partnerships__id_). 

## Update a partnership 

Lead providers can use `PUT /partnerships/{id}` endpoint to update a partnership with a new `delivery_partner_id`. 

For detailed technical information, view the `PUT /partnerships/{id}` [endpoint Swagger API documentation](/api/docs/v3#/Partnerships/put_api_v3_partnerships__id_).
