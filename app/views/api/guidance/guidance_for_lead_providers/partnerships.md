# Create, view and update partnerships 

## What are partnerships? 

Partnerships are agreements between schools, lead providers, and delivery partners to deliver training to early career teachers (ECTs) and mentors for a given cohort.  

## Understanding partnerships in the API 

The API allows lead providers to confirm, view, and update these agreements so that participants are correctly assigned to training. 

Lead providers should always check for existing partnerships before creating a new one: 

* use `GET /partnerships` to see if a partnership already exists for the school and cohort
* use `GET /schools` to check which programme type the school has chosen and if it’s already partnered with another lead provider 

Submitting a duplicate partnership (same school, lead provider, and cohort) will return a `422 error`. 

Additional partnerships by different lead providers for the same school and cohort are now allowed. This reflects the fact that some schools work with multiple lead providers in a single cohort. 

### Partnership ID 

Each confirmed partnership has a unique identifier (`id`), returned in the `GET /partnerships` response. This ID represents the agreement between a school, delivery partner, and lead provider for a given cohort. 

### Programme choices now set per participant 

We’ve removed challenge fields (`challenged_reason`, `challenged_at`, `status`) from partnership responses because schools now make changes at an individual participant level (for example, moving an ECT to a different provider) rather than challenging a school-wide partnership. 

If lead providers think a school has assigned the wrong provider to an ECT or mentor, they should ask the school to update the participant’s details in the service as a first step. 

Lead providers can check participant records to understand if a school is still working with them. 

### School induction tutor details 

Each partnership record shows one school induction tutor (name and email): 

* schools may have multiple users in the service, but only one induction tutor is surfaced to lead providers via the API 
* when schools first sign in after registration opens, they must provide the name and email of the induction tutor. That is what the API returns 

### Expression of interest records 

The `expression_of_interest` field in the `GET /schools` and `GET /schools/{id}` endpoints shows lead providers whether a school has any participants registered with them for that cohort. 

Schools now choose lead providers per participant, so this field reflects individual registrations, not a school-wide choice. A school may therefore show `expression_of_interest = TRUE` for more than one lead provider. 

#### Example scenarios 

| Scenario |   `expression_of_interest` | 
| ------------ | ------------- |  
| School has registered at least one participant with the lead provider for the chosen cohort | `TRUE`|  
| A partnership is confirmed for the cohort | `TRUE` (stays `TRUE` even if participants later leave, or switch lead provider or programme type) | 
| No participants registered with the lead provider | `FALSE` |  
| No partnership for the cohort and the school reports all participants have left or are no longer training with the lead provider | Changes from `TRUE` to `FALSE` |  

## Create a partnership 

``` 
POST /partnerships 
``` 

Request bodies must include: 

* `cohort` 
* `school_id` 
* `delivery_partner_id` 
 
For more detailed technical information, view the `POST /partnerships` [endpoint Swagger API documentation](/api/docs/v3#/Partnerships/post_api_v3_partnerships). 

### When lead providers can create a partnership 

Lead providers can create a partnership even if the school hasn’t registered participants. The only exceptions are when the cohort has not opened, or the school is doing school-led training. 
 
### Continuing into future cohorts 

During registration, induction tutors confirm whether to continue the partnership into the new cohort. They can carry forward the school’s most recent partnership, even if it’s from an earlier year. 

This reduces the need for lead providers to manually resubmit partnerships each cohort. 

## Roll over partnerships 

Schools can roll over their most recent partnership (not only from the previous cohort). 

## Multiple partnerships 

Previously, schools had a default partnership with a single lead provider for each cohort. 

We’ve changed this for the 2026 cohort to reflect that some schools need to set up partnerships with more than one lead provider. 

The API now supports multiple partnerships for a school in the same cohort: 

* each lead provider can create one partnership per school per cohort
* different providers can have partnerships with the same school (for example, if an ECT transfers and stays with their previous provider)
* if a school needs several delivery partners under the same provider in the same cohort, lead providers must notify us (via Teams or email). We’ll then add these additional partnerships manually 

In the API: 

* `GET /partnerships` may return more than one partnership for the same school and cohort
* `in_partnership` will state `TRUE` if any partnership exists and `FALSE` if none exist

## Find schools and delivery partners 

### Find schools delivering training 

``` 
GET /schools?filter[cohort]=year 
``` 

This endpoint returns schools eligible for funded training in a given cohort. Lead providers can check details on the type of training programme schools have chosen to deliver, and whether they’ve got confirmed partnerships in place. 

Requests must include: 

* `cohort` 

Lead providers can also filter by URN. For example, `GET /schools?filter[cohort]=2024&filter[urn]=123456`. 

For more detailed technical information, view the `GET /schools` [endpoint Swagger API documentation](/api/docs/v3#/Schools/get_api_v3_schools). 

### What the API will show 
 
The API shows schools eligible for funded training in a given cohort or schools with existing partnerships which have become ineligible.  

### What the API will not show 
 
The API will not show schools that are ineligible for funding in a given cohort. 
 
If a school’s eligibility changes from one cohort to the next, results will default according to the school's latest eligibility. For example, if a school was eligible for funding in the 2025 cohort but becomes ineligible for funding in 2026, the API will not show the school in the 2026 cohort. 

### View a specific school 

``` 
GET /schools/{id}?filter[cohort]={year} 
``` 

This endpoint shows details including the programme type choice and confirmed partnerships for a single school in a given cohort.  

Requests must include:  
 
* `cohort` 

For more detailed technical information, view the `GET /schools/{id}` [endpoint Swagger API documentation](/api/docs/v3#/Schools/get_api_v3_schools__id_). 

### Find delivery partner IDs 

``` 
GET /delivery-partners 
``` 

Each delivery partner has a unique `delivery_partner_id`. This ID is required when creating partnerships with a school and delivery partner. 

Lead providers can filter results by adding a `cohort` filter to the parameter. For example, GET `/api/delivery-partners?filter[cohort]=2024`.  

For more detailed technical information, view the `GET /delivery-partners` [endpoint Swagger API documentation](/api/docs/v3#/Delivery%20Partners/get_api_v3_delivery_partners). 

### View a specific delivery partner 

``` 
GET /delivery-partners/{id} 
```  

Lead providers can use this endpoint to see if a specific delivery partner is registered to deliver training for a cohort. 

For more detailed technical information, view the `GET /delivery-partners/{id}` [endpoint Swagger API documentation](/api/docs/v3#/Delivery%20Partners/get_api_v3_delivery_partners__id_). 

## View partnerships 

### View all partnerships 

``` 
GET /partnerships 
``` 

This endpoint lists all partnerships, with an optional cohort filter. 

For more detailed technical information, view the `GET /partnerships` [endpoint Swagger API documentation](/api/docs/v3#/Partnerships/get_api_v3_partnerships). 

### View an individual partnership 

``` 
GET /partnerships/{id} 
``` 

This endpoint returns details of individual partnerships. 

For more detailed technical information, view the `GET /partnerships/{id}` [endpoint Swagger API documentation](/api/docs/v3#/Partnerships/get_api_v3_partnerships__id_).  

## Update a partnership 

``` 
PUT /partnerships/{id} 
``` 

Lead providers can use this endpoint to update a partnership with a new `delivery_partner_id`. 

For more detailed technical information, view the `PUT /partnerships/{id}` [endpoint Swagger API documentation](/api/docs/v3#/Partnerships/put_api_v3_partnerships__id_). 

## Partnerships troubleshooting 

### Missing participants 

Lead providers should check if the school has them as the lead provider for any ECTs or mentors for that cohort. 

### Receiving data from a non-partnered school 

This can happen if an ECT transfers but continues training with their previous provider. 

## Example partnership response (challenge fields removed) 

```{
  "data": { 
    "id": "cd3a12347-7308-4879-942a-c4a70ced400a", 
    "type": "partnership", 
    "attributes": { 
      "cohort": 2024, 
      "urn": "123456", 
      "school_id": "24b61d1c-ad95-4000-aee0-afbdd542294a", 
      "delivery_partner_id": "db2fbf67-b7b7-454f-a1b7-0020411e2314", 
      "delivery_partner_name": "Delivery Partner Example", 
      "induction_tutor_name": "John Doe", 
      "induction_tutor_email": "john.doe@example.com", 
      "updated_at": "2024-05-31T02:22:32.000Z", 
      "created_at": "2024-05-31T02:22:32.000Z" 
    } 
  } 
}
```
