# Create, view and update partnerships 

## What are partnerships 

Partnerships are agreements between schools, lead providers, and delivery partners to deliver training to early career teachers (ECTs) and mentors for a given cohort.  

## Understanding partnerships in the API 

The API allows lead providers to confirm, view, and update these relationships so that participants are correctly assigned to training. 

Lead providers should always check for existing partnerships before creating a new one: 

* use `GET /partnerships` to see if a partnership already exists for the school and cohort
* use `GET /schools` to check if the school is already partnered with another lead provider 

Submitting a duplicate partnership (same school, lead provider, and cohort) will return a `422 error`. 

Additional partnerships by different lead providers for the same school and cohort are now allowed. 

### Partnership ID 

Each confirmed partnership has a unique identifier (`id`), returned in the `GET /partnerships` response. This ID represents the relationship between a school, delivery partner, and lead provider for a given cohort. 

### Programme choices now set per participant 

Partnership responses no longer include challenge fields (`challenged_reason`, `challenged_at`, `status`) because schools now make changes at participant level (for example, moving an ECT to a different provider).  

If lead providers think a school has assigned the wrong provider to an ECT, they should ask the school to update the ECT’s details in the service as a first step. 

Lead providers should check participant records to understand if a school is still working with them. 

### School induction tutor details 

Each partnership record shows one school induction tutor (name and email): 

* schools may have multiple users in the service, but only one induction tutor is surfaced to lead providers via the API
* when schools first sign in after registration opens, they must provide the name and email of the induction tutor. That is what the API returns
* these details may change more often as schools update their accounts 

### Default training assignment 

Once a partnership is confirmed, any new participants the school registers will default to training with the agreed lead provider and delivery partner. Participants registered before confirmation remain as expressions of interest until linked, and some transferred participants may continue training with their previous provider. 

For example, once a lead provider confirms a partnership for 2026/27, any new participants added by the induction tutor will be assigned to that lead provider and their delivery partner. 

### Expression of interest records 

The `expression_of_interest` field in the `GET /schools` and `GET /schools/{id}` endpoints shows lead providers whether a school has any participants registered with them. 

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

Requests bodies must include: 

* `cohort`
* `school_id`
* `delivery_partner_id` 

For more detailed technical information, view the `POST /partnerships` [endpoint Swagger API documentation](/api/docs/v3#/Partnerships/post_api_v3_partnerships).

### When lead providers can create a partnership 
 
Lead providers can create a partnership even if the school hasn’t registered participants. The only exceptions are when the cohort has not opened, or the school is doing its own training.
 
### Continuing into future cohorts 
 
The API assumes schools want to continue with their existing lead provider. 

During the school registration journey, induction tutors are prompted to confirm that the partnership should roll over into the new cohort. 

### If a school had a previous provider 

This should no longer be an issue because we now allow multiple partnerships. 

### If a school chose `school-led` by mistake when registering a participant 

Lead providers can correct this using the `POST /partnerships` endpoint. 

Confirm with the school first, then submit `school_id` and `delivery_partner_id`. 

### If a school chose `school-led` by mistake 

Lead providers can correct this using the `POST /partnerships` endpoint. 
 
Confirm with the school first, then submit `school_id` and `delivery_partner_id`. 

## Rolling over partnerships 

Schools can roll over their most recent partnership (not only from the previous cohort). 

This reduces the need for lead providers to manually resubmit partnerships each academic year. 

## Multiple partnerships 

Previously, schools had a default partnership with a single lead provider for each cohort. 

We’ve changed this for the 2026 cohort to reflect that some schools need to set up partnerships with more than one lead provider. 

The API now supports multiple partnerships for a school in the same cohort: 

* each lead provider can create one partnership per school per cohort
* different providers can have partnerships with the same school (for example, if an ECT transfers and stays with their previous provider)
* if a school needs several delivery partners under the same provider in the same cohort, lead providers must notify us (via Teams or email). We will then add these additional partnerships manually 

In the API: 

* `GET /partnerships` may return more than one partnership for the same school and cohort
* `in_partnership` will state `TRUE` if any partnership exists and `FALSE` if none exist

## Finding schools and delivery partners 

### Find schools delivering training 

```
GET /schools?filter[cohort]=year 
```

This endpoint returns schools eligible for funded training in a given cohort. Lead providers can check details on the type of training programme schools have chosen to deliver, and whether they’ve got confirmed partnerships in place.  

Requests must include: 

* `cohort`

Lead providers can also filter by URN. For example, `GET /schools/filter[cohort]=2024&filter[urn]=123456`. 

#### What the API will show 
 
The API shows schools eligible for funded training in a given cohort or schools with existing partnerships which have become ineligible.  

#### What the API will not show 
 
The API will not show schools that are ineligible for funding in a given cohort. 
 
If a school’s eligibility changes from one cohort to the next, results will default according to the latest school eligibility. For example, if a school was eligible for funding in the 2025 cohort but becomes ineligible for funding in 2026, the API will not show the school in the 2026 cohort. 

For more detailed technical information, see the `GET /schools` [endpoint Swagger API documentation](/api/docs/v3#/Schools/get_api_v3_schools). 

### View a specific school 

```
GET /schools/{id}?filter[cohort]={year} 
```

This endpoint shows the programme type and confirmed partnerships for a single school in a given cohort.  

Lead providers can check details on the type of training programme the school has chosen to deliver, and whether they have a confirmed partnership in place. 

Requests must include: 

* `cohort`

For more detailed technical information, view the `GET /schools/{id}` [endpoint Swagger API documentation](/api/docs/v3#/Schools/get_api_v3_schools__id_). 

### Find delivery partner IDs 

```
GET /delivery-partners 
```

Each delivery partner has a unique `delivery_partner_id`. This ID is required when creating partnerships with a school and delivery partner. 

Lead providers can filter results by adding a `cohort` filter to the parameter. For example, `GET /delivery-partners?filter[cohort]=2024`. 

For more detailed technical information, view the GET `delivery-partners` [endpoint Swagger API documentation](/api/docs/v3#/Delivery%20Partners/get_api_v3_delivery_partners). 

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

Check if the school has confirmed a partnership for that cohort. 

### Incorrect partnerships 

Lead providers should contact DfE if a school appears to be partnered incorrectly. 

### Receiving data from a non-partnered school 

Can happen if an ECT transfers but continues training with their previous provider. 

## Example partnership response (challenge fields removed) 

```
{ 
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
