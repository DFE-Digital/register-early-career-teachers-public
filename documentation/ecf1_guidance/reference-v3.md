
# Lead provider API - 3.0.0


The lead provider API for DfE’s manage teacher CPD service.

## Base URLs


 **Sandbox** 
 [https://sb.manage-training-for-early-career-teachers.education.gov.uk](https://sb.manage-training-for-early-career-teachers.education.gov.uk) 

 **Current environment** 
 [/](/) 

 **Production** 
 [https://manage-training-for-early-career-teachers.education.gov.uk](https://manage-training-for-early-career-teachers.education.gov.uk) 

## GET /api/v3/delivery-partners


 _Note, this endpoint is new.Retrieve delivery partners_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| filter | query | object | false | Refine delivery partners to return.<br/>This consumes a [DeliveryPartnersFilter](#deliverypartnersfilter) schema.<br/> | filter[cohort]=2021 | 
| page | query | object | false | Pagination options to navigate through the list of delivery partners.<br/>This consumes a [Pagination](#pagination) schema.<br/> | page[page]=1&page[per\_page]=5 | 
| sort | query | array | false | Sort delivery partners being returned.<br/>This consumes a [DeliveryPartnersSort](#deliverypartnerssort) schema.<br/> | sort=-updated\_at | 


### Responses


| Status | Description |
| ---- | ---- |
| 200 | Successfully return a list of delivery partners<br/>This response returns a [DeliveryPartnersResponse](#deliverypartnersresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.<br/> | 


### Response examples

200 - Successfully return a list of delivery partners
This response returns a [DeliveryPartnersResponse](#deliverypartnersresponse) schema.

```
{
  "data": [
    {
      "id": "cd3a12347-7308-4879-942a-c4a70ced400a",
      "type": "delivery-partner",
      "attributes": {
        "name": "Awesome Delivery Partner Ltd",
        "cohort": [
          "2021",
          "2022"
        ],
        "created_at": "2021-05-31T02:22:32.000Z",
        "updated_at": "2021-05-31T02:22:32.000Z"
      }
    }
  ]
}
```

401 - Unauthorized
This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.

```
{
  "error": "HTTP Token: Access denied"
}
```


---


## GET /api/v3/delivery-partners/{id}


 _Note, this endpoint is new.Retrieve a specific delivery partner_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The unique ID of the delivery partner<br/> | 00acafd3-e6f6-41e7-a770-3207be94f755 | 


### Responses


| Status | Description |
| ---- | ---- |
| 200 | Successfully return a specific delivery partner<br/>This response returns a [DeliveryPartnerResponse](#deliverypartnerresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.<br/> | 
| 404 | Not Found<br/>This response returns a [NotFoundResponse](#notfoundresponse) schema.<br/> | 


### Response examples

200 - Successfully return a specific delivery partner
This response returns a [DeliveryPartnerResponse](#deliverypartnerresponse) schema.

```
{
  "data": {
    "id": "cd3a12347-7308-4879-942a-c4a70ced400a",
    "type": "delivery-partner",
    "attributes": {
      "name": "Awesome Delivery Partner Ltd",
      "cohort": [
        "2021",
        "2022"
      ],
      "created_at": "2021-05-31T02:22:32.000Z",
      "updated_at": "2021-05-31T02:22:32.000Z"
    }
  }
}
```

401 - Unauthorized
This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.

```
{
  "error": "HTTP Token: Access denied"
}
```

404 - Not Found
This response returns a [NotFoundResponse](#notfoundresponse) schema.

```
{
  "title": "string",
  "detail": "string"
}
```


---


## GET /api/v3/partnerships/ecf


 _Note, this endpoint is new.Retrieve multiple ECF partnerships_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| filter | query | object | false | Refine partnerships to return.<br/>This consumes a [PartnershipsFilter](#partnershipsfilter) schema.<br/> | filter[cohort]=2021,2022 | 
| page | query | object | false | Pagination options to navigate through the list of partnerships.<br/>This consumes a [Pagination](#pagination) schema.<br/> | page[page]=1&page[per\_page]=5 | 
| sort | query | array | false | Sort partnerships being returned.<br/>This consumes a [PartnershipsSort](#partnershipssort) schema.<br/> | sort=-updated\_at | 


### Responses


| Status | Description |
| ---- | ---- |
| 200 | A list of ECF partnerships<br/>This response returns a [MultipleECFPartnershipsResponse](#multipleecfpartnershipsresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.<br/> | 


### Response examples

200 - A list of ECF partnerships
This response returns a [MultipleECFPartnershipsResponse](#multipleecfpartnershipsresponse) schema.

```
{
  "data": [
    {
      "id": "cd3a12347-7308-4879-942a-c4a70ced400a",
      "type": "partnership",
      "attributes": {
        "cohort": 2021,
        "urn": "123456",
        "school_id": "dd4a11347-7308-4879-942a-c4a70ced400v",
        "delivery_partner_id": "cd3a12347-7308-4879-942a-c4a70ced400a",
        "delivery_partner_name": "Delivery Partner Example",
        "status": "challenged",
        "challenged_reason": "mistake",
        "challenged_at": "2021-05-31T02:22:32.000Z",
        "induction_tutor_name": "John Doe",
        "induction_tutor_email": "john.doe@example.com",
        "updated_at": "2021-05-31T02:22:32.000Z",
        "created_at": "2021-05-31T02:22:32.000Z"
      }
    }
  ]
}
```

401 - Unauthorized
This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.

```
{
  "error": "HTTP Token: Access denied"
}
```


---


## POST /api/v3/partnerships/ecf


 _Note, this endpoint is new.Create an ECF partnership with a school and delivery partner_ 

### Request body


This consumes a [ECFPartnershipRequest](#ecfpartnershiprequest) schema.

### Request example


```
{
  "data": {
    "type": "ecf-partnership",
    "attributes": {
      "cohort": "2021",
      "school_id": "24b61d1c-ad95-4000-aee0-afbdd542294a",
      "delivery_partner_id": "db2fbf67-b7b7-454f-a1b7-0020411e2314"
    }
  }
}
```


### Responses


| Status | Description |
| ---- | ---- |
| 200 | Create an ECF partnership<br/>This response returns a [ECFPartnershipResponse](#ecfpartnershipresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.<br/> | 
| 422 | Unprocessable entity<br/>This response returns a [ECFPartnershipRequestErrorResponse](#ecfpartnershiprequesterrorresponse) schema.<br/> | 


### Response examples

200 - Create an ECF partnership
This response returns a [ECFPartnershipResponse](#ecfpartnershipresponse) schema.

```
{
  "data": {
    "id": "cd3a12347-7308-4879-942a-c4a70ced400a",
    "type": "partnership",
    "attributes": {
      "cohort": 2021,
      "urn": "123456",
      "school_id": "dd4a11347-7308-4879-942a-c4a70ced400v",
      "delivery_partner_id": "db2fbf67-b7b7-454f-a1b7-0020411e2314",
      "delivery_partner_name": "Delivery Partner Example",
      "status": "active",
      "challenged_reason": null,
      "challenged_at": null,
      "induction_tutor_name": "John Doe",
      "induction_tutor_email": "john.doe@example.com",
      "updated_at": "2021-05-31T02:22:32.000Z",
      "created_at": "2021-05-31T02:22:32.000Z"
    }
  }
}
```

401 - Unauthorized
This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.

```
{
  "error": "HTTP Token: Access denied"
}
```

422 - Unprocessable entity
This response returns a [ECFPartnershipRequestErrorResponse](#ecfpartnershiprequesterrorresponse) schema.

```
{
  "error": [
    {
      "title": "Recruited by other provider",
      "detail": "This partnership cannot be created as it has already partnered with another provider"
    }
  ]
}
```


---


## GET /api/v3/partnerships/ecf/{id}


 _Note, this endpoint is new.Get a single ECF partnership_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The unique ID of the partnership<br/> | 00acafd3-e6f6-41e7-a770-3207be94f755 | 


### Responses


| Status | Description |
| ---- | ---- |
| 200 | A single partnership<br/>This response returns a [ECFPartnershipResponse](#ecfpartnershipresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.<br/> | 
| 404 | Not Found<br/>This response returns a [NotFoundResponse](#notfoundresponse) schema.<br/> | 


### Response examples

200 - A single partnership
This response returns a [ECFPartnershipResponse](#ecfpartnershipresponse) schema.

```
{
  "data": {
    "id": "cd3a12347-7308-4879-942a-c4a70ced400a",
    "type": "partnership",
    "attributes": {
      "cohort": 2021,
      "urn": "123456",
      "school_id": "dd4a11347-7308-4879-942a-c4a70ced400v",
      "delivery_partner_id": "cd3a12347-7308-4879-942a-c4a70ced400a",
      "delivery_partner_name": "Delivery Partner Example",
      "status": "challenged",
      "challenged_reason": "mistake",
      "challenged_at": "2021-05-31T02:22:32.000Z",
      "induction_tutor_name": "John Doe",
      "induction_tutor_email": "john.doe@example.com",
      "updated_at": "2021-05-31T02:22:32.000Z",
      "created_at": "2021-05-31T02:22:32.000Z"
    }
  }
}
```

401 - Unauthorized
This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.

```
{
  "error": "HTTP Token: Access denied"
}
```

404 - Not Found
This response returns a [NotFoundResponse](#notfoundresponse) schema.

```
{
  "title": "string",
  "detail": "string"
}
```


---


## PUT /api/v3/partnerships/ecf/{id}


 _Note, this endpoint is new.Update a partnership’s delivery partner in an existing partnership in a cohort_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The ID of the partnership to update<br/> | 28c461ee-ffc0-4e56-96bd-788579a0ed75 | 


### Request body


This consumes a [ECFPartnershipUpdateRequest](#ecfpartnershipupdaterequest) schema.

### Request example


```
{
  "data": {
    "type": "ecf-partnership-update",
    "attributes": {
      "delivery_partner_id": "db2fbf67-b7b7-454f-a1b7-0020411e2314"
    }
  }
}
```


### Responses


| Status | Description |
| ---- | ---- |
| 200 | Update an ECF partnership<br/>This response returns a [ECFPartnershipResponse](#ecfpartnershipresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.<br/> | 
| 422 | Unprocessable entity<br/>This response returns a [ECFPartnershipRequestErrorResponse](#ecfpartnershiprequesterrorresponse) schema.<br/> | 
| 404 | Not Found<br/>This response returns a [NotFoundResponse](#notfoundresponse) schema.<br/> | 


### Response examples

200 - Update an ECF partnership
This response returns a [ECFPartnershipResponse](#ecfpartnershipresponse) schema.

```
{
  "data": {
    "id": "cd3a12347-7308-4879-942a-c4a70ced400a",
    "type": "partnership",
    "attributes": {
      "cohort": 2021,
      "urn": "123456",
      "school_id": "dd4a11347-7308-4879-942a-c4a70ced400v",
      "delivery_partner_id": "db2fbf67-b7b7-454f-a1b7-0020411e2314",
      "delivery_partner_name": "Delivery Partner Example",
      "status": "active",
      "challenged_reason": null,
      "challenged_at": null,
      "induction_tutor_name": "John Doe",
      "induction_tutor_email": "john.doe@example.com",
      "updated_at": "2021-05-31T02:22:32.000Z",
      "created_at": "2021-05-31T02:22:32.000Z"
    }
  }
}
```

401 - Unauthorized
This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.

```
{
  "error": "HTTP Token: Access denied"
}
```

422 - Unprocessable entity
This response returns a [ECFPartnershipRequestErrorResponse](#ecfpartnershiprequesterrorresponse) schema.

```
{
  "error": [
    {
      "title": "Recruited by other provider",
      "detail": "This partnership cannot be created as it has already partnered with another provider"
    }
  ]
}
```

404 - Not Found
This response returns a [NotFoundResponse](#notfoundresponse) schema.

```
{
  "title": "string",
  "detail": "string"
}
```


---


## GET /api/v3/schools/ecf


 _Note, this endpoint is new.Retrieve multiple ECF schools scoped to cohort_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| filter[cohort] | query | object | true | Refine schools to return.<br/>This consumes a [ECFSchoolsFilter](#ecfschoolsfilter) schema.<br/> | filter[cohort]=2021 | 
| filter[urn] | query | object | false | Refine schools to return.<br/>This consumes a [ECFSchoolsFilter](#ecfschoolsfilter) schema.<br/> | filter[urn]=106286 | 
| filter[updated\_since] | query | object | false | Refine schools to return.<br/>This consumes a [ECFSchoolsFilter](#ecfschoolsfilter) schema.<br/> | filter[updated\_since]=2020-11-13T11:21:55Z | 
| page | query | object | false | Pagination options to navigate through the list of schools.<br/>This consumes a [Pagination](#pagination) schema.<br/> | page[page]=1&page[per\_page]=5 | 
| sort | query | array | false | Sort schools being returned.<br/>This consumes a [ECFSchoolsSort](#ecfschoolssort) schema.<br/> | sort=-updated\_at | 


### Responses


| Status | Description |
| ---- | ---- |
| 200 | A list of schools for the given cohort<br/>This response returns a [MultipleECFSchoolsResponse](#multipleecfschoolsresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.<br/> | 


### Response examples

200 - A list of schools for the given cohort
This response returns a [MultipleECFSchoolsResponse](#multipleecfschoolsresponse) schema.

```
{
  "data": [
    {
      "id": "cd3a12347-7308-4879-942a-c4a70ced400a",
      "type": "school",
      "attributes": {
        "name": "School Example",
        "urn": "123456",
        "cohort": 2021,
        "in_partnership": "boolean",
        "induction_programme_choice": "not_yet_known",
        "created_at": "2021-05-31T02:22:32.000Z",
        "updated_at": "2021-05-31T02:22:32.000Z"
      }
    }
  ]
}
```

401 - Unauthorized
This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.

```
{
  "error": "HTTP Token: Access denied"
}
```


---


## GET /api/v3/schools/ecf/{id}


 _Note, this endpoint is new.Get a single ECF school scoped to cohort_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The unique ID of the school<br/> | 28c461ee-ffc0-4e56-96bd-788579a0ed75 | 
| filter[cohort] | query | object | true | Refine schools to return.<br/>This consumes a [ECFSchoolsFilter](#ecfschoolsfilter) schema.<br/> | filter[cohort]=2021 | 


### Responses


| Status | Description |
| ---- | ---- |
| 200 | A single school<br/>This response returns a [ECFSchoolResponse](#ecfschoolresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.<br/> | 
| 404 | Not Found<br/>This response returns a [NotFoundResponse](#notfoundresponse) schema.<br/> | 


### Response examples

200 - A single school
This response returns a [ECFSchoolResponse](#ecfschoolresponse) schema.

```
{
  "data": {
    "id": "cd3a12347-7308-4879-942a-c4a70ced400a",
    "type": "school",
    "attributes": {
      "name": "School Example",
      "urn": "123456",
      "cohort": 2021,
      "in_partnership": "boolean",
      "induction_programme_choice": "not_yet_known",
      "created_at": "2021-05-31T02:22:32.000Z",
      "updated_at": "2021-05-31T02:22:32.000Z"
    }
  }
}
```

401 - Unauthorized
This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.

```
{
  "error": "HTTP Token: Access denied"
}
```

404 - Not Found
This response returns a [NotFoundResponse](#notfoundresponse) schema.

```
{
  "title": "string",
  "detail": "string"
}
```


---


## GET /api/v3/participant-declarations


 _Note, this endpoint includes updated specifications.List all participant declarations_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| filter | query | object | false | Refine participant declarations to return.<br/>This consumes a [ParticipantDeclarationsFilter](#participantdeclarationsfilter) schema.<br/> | filter[participant\_id]=ab3a7848-1208-7679-942a-b4a70eed400a&filter[updated\_since]=2020-11-13T11:21:55Z | 
| page | query | object | false | Pagination options to navigate through the list of participant declarations.<br/>This consumes a [Pagination](#pagination) schema.<br/> | page[page]=1&page[per\_page]=5 | 


### Responses


| Status | Description |
| ---- | ---- |
| 200 | A list of participant declarations<br/>This response returns a [MultipleParticipantDeclarationsResponse](#multipleparticipantdeclarationsresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.<br/> | 


### Response examples

200 - A list of participant declarations
This response returns a [MultipleParticipantDeclarationsResponse](#multipleparticipantdeclarationsresponse) schema.

```
{
  "data": [
    {
      "id": "db3a7848-7308-4879-942a-c4a70ced400a",
      "type": "participant-declaration",
      "attributes": {
        "participant_id": "08d78829-f864-417f-8a30-cb7655714e28",
        "declaration_type": "started",
        "declaration_date": "2020-11-13T11:21:55Z",
        "course_identifier": "ecf-induction",
        "state": "eligible",
        "updated_at": "2020-11-13T11:21:55Z",
        "created_at": "2020-11-13T11:21:55Z",
        "delivery_partner_id": "99ca2223-8c1f-4ac8-985d-a0672e97694e",
        "statement_id": "99ca2223-8c1f-4ac8-985d-a0672e97694e",
        "clawback_statement_id": null,
        "ineligible_for_funding_reason": null,
        "mentor_id": "907f61ed-5770-4d38-b22c-1a4265939378",
        "uplift_paid": true,
        "evidence_held": "other",
        "has_passed": null,
        "lead_provider_name": "Example Institute"
      }
    }
  ]
}
```

401 - Unauthorized
This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.

```
{
  "error": "HTTP Token: Access denied"
}
```


---


## POST /api/v3/participant-declarations


 _Note, this endpoint includes updated specifications.Declare a participant has reached a milestone. Idempotent endpoint - submitting exact copy of a request will return the same response body as submitting it the first time._ 

### Request body


This consumes a [ParticipantDeclarationRequest](#participantdeclarationrequest) schema.

### Responses


| Status | Description |
| ---- | ---- |
| 200 | Successful<br/>This response returns a [SingleParticipantDeclarationResponse](#singleparticipantdeclarationresponse) schema.<br/> | 
| 422 | Bad or Missing parameter<br/>This response returns a [ErrorResponse](#errorresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.<br/> | 
| 400 | Bad Request<br/>This response returns a [BadRequestResponse](#badrequestresponse) schema.<br/> | 


### Response examples

200 - Successful
This response returns a [SingleParticipantDeclarationResponse](#singleparticipantdeclarationresponse) schema.

```
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant-declaration",
    "attributes": {
      "participant_id": "08d78829-f864-417f-8a30-cb7655714e28",
      "declaration_type": "started",
      "declaration_date": "2020-11-13T11:21:55Z",
      "course_identifier": "ecf-induction",
      "state": "eligible",
      "updated_at": "2020-11-13T11:21:55Z",
      "created_at": "2020-11-13T11:21:55Z",
      "delivery_partner_id": "99ca2223-8c1f-4ac8-985d-a0672e97694e",
      "statement_id": "99ca2223-8c1f-4ac8-985d-a0672e97694e",
      "clawback_statement_id": null,
      "ineligible_for_funding_reason": null,
      "mentor_id": "907f61ed-5770-4d38-b22c-1a4265939378",
      "uplift_paid": true,
      "evidence_held": "other",
      "has_passed": null,
      "lead_provider_name": "Example Institute"
    }
  }
}
```

422 - Bad or Missing parameter
This response returns a [ErrorResponse](#errorresponse) schema.

```
{
  "error": [
    {
      "title": "string",
      "detail": "string"
    }
  ]
}
```

401 - Unauthorized
This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.

```
{
  "error": "HTTP Token: Access denied"
}
```

400 - Bad Request
This response returns a [BadRequestResponse](#badrequestresponse) schema.

```
{
  "bad_request": "string"
}
```


---


## GET /api/v3/participant-declarations/{id}


 _Note, this endpoint includes updated specifications.Get single participant declaration_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The ID of the participant declaration ID<br/> | 9ed4612b-f8bd-44d9-b296-38ab103fadd2 | 


### Responses


| Status | Description |
| ---- | ---- |
| 200 | A single participant declaration<br/>This response returns a [SingleParticipantDeclarationResponse](#singleparticipantdeclarationresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.<br/> | 
| 404 | Not found<br/>This response returns a [NotFoundResponse](#notfoundresponse) schema.<br/> | 


### Response examples

200 - A single participant declaration
This response returns a [SingleParticipantDeclarationResponse](#singleparticipantdeclarationresponse) schema.

```
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant-declaration",
    "attributes": {
      "participant_id": "08d78829-f864-417f-8a30-cb7655714e28",
      "declaration_type": "started",
      "declaration_date": "2020-11-13T11:21:55Z",
      "course_identifier": "ecf-induction",
      "state": "eligible",
      "updated_at": "2020-11-13T11:21:55Z",
      "created_at": "2020-11-13T11:21:55Z",
      "delivery_partner_id": "99ca2223-8c1f-4ac8-985d-a0672e97694e",
      "statement_id": "99ca2223-8c1f-4ac8-985d-a0672e97694e",
      "clawback_statement_id": null,
      "ineligible_for_funding_reason": null,
      "mentor_id": "907f61ed-5770-4d38-b22c-1a4265939378",
      "uplift_paid": true,
      "evidence_held": "other",
      "has_passed": null,
      "lead_provider_name": "Example Institute"
    }
  }
}
```

401 - Unauthorized
This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.

```
{
  "error": "HTTP Token: Access denied"
}
```

404 - Not found
This response returns a [NotFoundResponse](#notfoundresponse) schema.

```
{
  "title": "string",
  "detail": "string"
}
```


---


## PUT /api/v3/participant-declarations/{id}/void


 _Note, this endpoint includes updated specifications.Void a declaration - it will not be soft-deleted_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The ID of the declaration to void<br/> | 28c461ee-ffc0-4e56-96bd-788579a0ed75 | 


### Responses


| Status | Description |
| ---- | ---- |
| 200 | Successful<br/>This response returns a [SingleParticipantDeclarationResponse](#singleparticipantdeclarationresponse) schema.<br/> | 


### Response examples

200 - Successful
This response returns a [SingleParticipantDeclarationResponse](#singleparticipantdeclarationresponse) schema.

```
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant-declaration",
    "attributes": {
      "participant_id": "08d78829-f864-417f-8a30-cb7655714e28",
      "declaration_type": "started",
      "declaration_date": "2020-11-13T11:21:55Z",
      "course_identifier": "ecf-induction",
      "state": "voided",
      "updated_at": "2020-11-13T11:21:55Z",
      "created_at": "2020-11-13T11:21:55Z",
      "delivery_partner_id": "99ca2223-8c1f-4ac8-985d-a0672e97694e",
      "statement_id": "99ca2223-8c1f-4ac8-985d-a0672e97694e",
      "clawback_statement_id": null,
      "ineligible_for_funding_reason": null,
      "mentor_id": "907f61ed-5770-4d38-b22c-1a4265939378",
      "uplift_paid": true,
      "evidence_held": "other",
      "has_passed": null,
      "lead_provider_name": "Example Institute"
    }
  }
}
```


---


## GET /api/v3/participants/ecf


 _Note, this endpoint includes updated specifications.Retrieve multiple participants, replaces /api/v3/participants_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| filter | query | object | false | Refine ECF participants to return.<br/>This consumes a [ECFParticipantFilter](#ecfparticipantfilter) schema.<br/> | filter[cohort]=2022&filter[from\_participant\_id]=439ac4fe-a003-417f-9694-07c45b3482f8&filter[training\_status]=active&filter[updated\_since]=2020-11-13T11:21:55Z | 
| page | query | object | false | Pagination options to navigate through the list of ECF participants.<br/>This consumes a [Pagination](#pagination) schema.<br/> | page[page]=1&page[per\_page]=5 | 
| sort | query | array | false | Sort ECF participants being returned.<br/>This consumes a [ECFParticipantsSort](#ecfparticipantssort) schema.<br/> | sort=-updated\_at | 


### Responses


| Status | Description |
| ---- | ---- |
| 200 | A list of ECF participants<br/>This response returns a [MultipleECFParticipantsResponse](#multipleecfparticipantsresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.<br/> | 


### Response examples

200 - A list of ECF participants
This response returns a [MultipleECFParticipantsResponse](#multipleecfparticipantsresponse) schema.

```
{
  "data": [
    {
      "id": "ac3d1243-7308-4879-942a-c4a70ced400a",
      "type": "participant",
      "attributes": {
        "full_name": "Jane Smith",
        "teacher_reference_number": "1234567",
        "updated_at": "2021-05-31T02:22:32.000Z",
        "ecf_enrolments": [
          {
            "training_record_id": "000a97ff-d2a9-4779-a397-9bfd9063072e",
            "email": "jane.smith@some-school.example.com",
            "mentor_id": "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
            "school_urn": "106286",
            "participant_type": "ect",
            "cohort": "2021",
            "training_status": "active",
            "participant_status": "active",
            "teacher_reference_number_validated": true,
            "eligible_for_funding": true,
            "pupil_premium_uplift": true,
            "sparsity_uplift": true,
            "schedule_identifier": "ecf-standard-january",
            "delivery_partner_id": "cd3a12347-7308-4879-942a-c4a70ced400a",
            "withdrawal": null,
            "deferral": null,
            "created_at": "2021-05-31T02:22:32.000Z",
            "induction_end_date": "2022-01-12",
            "mentor_funding_end_date": "2021-04-19",
            "cohort_changed_after_payments_frozen": true,
            "mentor_ineligible_for_funding_reason": "completed_declaration_received"
          }
        ],
        "participant_id_changes": [
          {
            "from_participant_id": "23dd8d66-e11f-4139-9001-86b4f9abcb02",
            "to_participant_id": "ac3d1243-7308-4879-942a-c4a70ced400a",
            "changed_at": "2021-05-31T02:22:32.000Z"
          }
        ]
      }
    }
  ]
}
```

401 - Unauthorized
This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.

```
{
  "error": "HTTP Token: Access denied"
}
```


---


## GET /api/v3/participants/ecf/{id}


 _Note, this endpoint includes updated specifications.Get a single ECF participant_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The ID of the ECF participant.<br/> | 28c461ee-ffc0-4e56-96bd-788579a0ed75 | 


### Responses


| Status | Description |
| ---- | ---- |
| 200 | A single ECF participant<br/>This response returns a [ECFParticipantResponse](#ecfparticipantresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.<br/> | 
| 404 | Not Found<br/>This response returns a [NotFoundResponse](#notfoundresponse) schema.<br/> | 


### Response examples

200 - A single ECF participant
This response returns a [ECFParticipantResponse](#ecfparticipantresponse) schema.

```
{
  "data": {
    "id": "ac3d1243-7308-4879-942a-c4a70ced400a",
    "type": "participant",
    "attributes": {
      "full_name": "Jane Smith",
      "teacher_reference_number": "1234567",
      "updated_at": "2021-05-31T02:22:32.000Z",
      "ecf_enrolments": [
        {
          "training_record_id": "000a97ff-d2a9-4779-a397-9bfd9063072e",
          "email": "jane.smith@some-school.example.com",
          "mentor_id": "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
          "school_urn": "106286",
          "participant_type": "ect",
          "cohort": "2021",
          "training_status": "active",
          "participant_status": "active",
          "teacher_reference_number_validated": true,
          "eligible_for_funding": true,
          "pupil_premium_uplift": true,
          "sparsity_uplift": true,
          "schedule_identifier": "ecf-standard-january",
          "delivery_partner_id": "cd3a12347-7308-4879-942a-c4a70ced400a",
          "withdrawal": null,
          "deferral": null,
          "created_at": "2021-05-31T02:22:32.000Z",
          "induction_end_date": "2022-01-12",
          "mentor_funding_end_date": "2021-04-19",
          "cohort_changed_after_payments_frozen": true,
          "mentor_ineligible_for_funding_reason": "completed_declaration_received"
        }
      ],
      "participant_id_changes": [
        {
          "from_participant_id": "23dd8d66-e11f-4139-9001-86b4f9abcb02",
          "to_participant_id": "ac3d1243-7308-4879-942a-c4a70ced400a",
          "changed_at": "2021-05-31T02:22:32.000Z"
        }
      ]
    }
  }
}
```

401 - Unauthorized
This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.

```
{
  "error": "HTTP Token: Access denied"
}
```

404 - Not Found
This response returns a [NotFoundResponse](#notfoundresponse) schema.

```
{
  "title": "string",
  "detail": "string"
}
```


---


## GET /api/v3/participants/ecf/transfers


 _Note, this endpoint is new.Retrieve multiple ECF participant transfers_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| filter | query | object | false | Refine participant transfers to return.<br/>This consumes a [ListFilter](#listfilter) schema.<br/> | filter[updated\_since]=2020-11-13T11:21:55Z | 
| page | query | object | false | Pagination options to navigate through the list of participant transfers.<br/>This consumes a [Pagination](#pagination) schema.<br/> | page[page]=1&page[per\_page]=5 | 


### Responses


| Status | Description |
| ---- | ---- |
| 200 | A list of ECF participant transfers<br/>This response returns a [MultipleECFParticipantTransferResponse](#multipleecfparticipanttransferresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.<br/> | 


### Response examples

200 - A list of ECF participant transfers
This response returns a [MultipleECFParticipantTransferResponse](#multipleecfparticipanttransferresponse) schema.

```
{
  "data": [
    {
      "id": "db3a7848-7308-4879-942a-c4a70ced400a",
      "type": "participant-transfer",
      "attributes": {
        "updated_at": "2021-05-31T02:22:32.000Z",
        "transfers": {
          "training_record_id": "000a97ff-d2a9-4779-a397-9bfd9063072e",
          "transfer_type": "new_provider",
          "status": "complete",
          "leaving": {
            "school_urn": "123456",
            "provider": "Old Institute",
            "date": "2021-05-31"
          },
          "joining": {
            "school_urn": "654321",
            "provider": "New Institute",
            "date": "2021-06-01"
          },
          "created_at": "2021-05-31T02:22:32.000Z"
        }
      }
    }
  ]
}
```

401 - Unauthorized
This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.

```
{
  "error": "HTTP Token: Access denied"
}
```


---


## PUT /api/v3/participants/ecf/{id}/defer


 _Note, this endpoint includes updated specifications.Notify that an ECF participant is taking a break from their course_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The ID of the participant to defer<br/> | 28c461ee-ffc0-4e56-96bd-788579a0ed75 | 


### Request body


This consumes a [ECFParticipantDeferRequest](#ecfparticipantdeferrequest) schema.

### Request example


```
{
  "data": {
    "type": "participant-defer",
    "attributes": {
      "reason": "career-break",
      "course_identifier": "ecf-mentor"
    }
  }
}
```


### Responses


| Status | Description |
| ---- | ---- |
| 200 | The ECF participant being deferred<br/>This response returns a [ECFParticipantResponse](#ecfparticipantresponse) schema.<br/> | 


### Response examples

200 - The ECF participant being deferred
This response returns a [ECFParticipantResponse](#ecfparticipantresponse) schema.

```
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant",
    "attributes": {
      "full_name": "Jane Smith",
      "teacher_reference_number": "1234567",
      "updated_at": "2021-05-31T02:22:32.000Z",
      "ecf_enrolments": [
        {
          "training_record_id": "000a97ff-d2a9-4779-a397-9bfd9063072e",
          "email": "jane.smith@some-school.example.com",
          "mentor_id": "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
          "school_urn": "106286",
          "participant_type": "ect",
          "cohort": "2021",
          "training_status": "withdrawn",
          "participant_status": "withdrawn",
          "teacher_reference_number_validated": true,
          "eligible_for_funding": true,
          "pupil_premium_uplift": true,
          "sparsity_uplift": true,
          "schedule_identifier": "ecf-standard-january",
          "delivery_partner_id": "cd3a12347-7308-4879-942a-c4a70ced400a",
          "withdrawal": null,
          "deferral": {
            "reason": "other",
            "date": "2021-06-31T02:22:32.000Z"
          },
          "created_at": "2022-11-09T16:07:38Z",
          "induction_end_date": "2022-01-12",
          "mentor_funding_end_date": "2021-04-19",
          "cohort_changed_after_payments_frozen": true,
          "mentor_ineligible_for_funding_reason": null
        }
      ],
      "participant_id_changes": [
        {
          "from_participant_id": "23dd8d66-e11f-4139-9001-86b4f9abcb02",
          "to_participant_id": "db3a7848-7308-4879-942a-c4a70ced400a",
          "changed_at": "2023-09-23T02:22:32.000Z"
        }
      ]
    }
  }
}
```


---


## PUT /api/v3/participants/ecf/{id}/resume


 _Note, this endpoint includes updated specifications.Notify that an ECF participant is resuming their course_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The ID of the participant to resume<br/> | 28c461ee-ffc0-4e56-96bd-788579a0ed75 | 


### Request body


This consumes a [ECFParticipantResumeRequest](#ecfparticipantresumerequest) schema.

### Request example


```
{
  "data": {
    "type": "participant-resume",
    "attributes": {
      "course_identifier": "ecf-mentor"
    }
  }
}
```


### Responses


| Status | Description |
| ---- | ---- |
| 200 | The ECF participant being resumed<br/>This response returns a [ECFParticipantResponse](#ecfparticipantresponse) schema.<br/> | 


### Response examples

200 - The ECF participant being resumed
This response returns a [ECFParticipantResponse](#ecfparticipantresponse) schema.

```
{
  "data": {
    "id": "ac3d1243-7308-4879-942a-c4a70ced400a",
    "type": "participant",
    "attributes": {
      "full_name": "Jane Smith",
      "teacher_reference_number": "1234567",
      "updated_at": "2021-05-31T02:22:32.000Z",
      "ecf_enrolments": [
        {
          "training_record_id": "000a97ff-d2a9-4779-a397-9bfd9063072e",
          "email": "jane.smith@some-school.example.com",
          "mentor_id": "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
          "school_urn": "106286",
          "participant_type": "ect",
          "cohort": "2021",
          "training_status": "active",
          "participant_status": "active",
          "teacher_reference_number_validated": true,
          "eligible_for_funding": true,
          "pupil_premium_uplift": true,
          "sparsity_uplift": true,
          "schedule_identifier": "ecf-standard-january",
          "delivery_partner_id": "cd3a12347-7308-4879-942a-c4a70ced400a",
          "withdrawal": null,
          "deferral": null,
          "created_at": "2021-05-31T02:22:32.000Z",
          "induction_end_date": "2022-01-12",
          "mentor_funding_end_date": "2021-04-19",
          "cohort_changed_after_payments_frozen": true,
          "mentor_ineligible_for_funding_reason": "completed_declaration_received"
        }
      ],
      "participant_id_changes": [
        {
          "from_participant_id": "23dd8d66-e11f-4139-9001-86b4f9abcb02",
          "to_participant_id": "ac3d1243-7308-4879-942a-c4a70ced400a",
          "changed_at": "2021-05-31T02:22:32.000Z"
        }
      ]
    }
  }
}
```


---


## PUT /api/v3/participants/ecf/{id}/withdraw


 _Note, this endpoint includes updated specifications.Notify that an ECF participant has withdrawn from their course_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The ID of the participant to withdraw<br/> | 28c461ee-ffc0-4e56-96bd-788579a0ed75 | 


### Request body


This consumes a [ECFParticipantWithdrawRequest](#ecfparticipantwithdrawrequest) schema.

### Request example


```
{
  "data": {
    "type": "participant-withdraw",
    "attributes": {
      "reason": "left-teaching-profession",
      "course_identifier": "ecf-mentor"
    }
  }
}
```


### Responses


| Status | Description |
| ---- | ---- |
| 200 | The ECF participant being withdrawn<br/>This response returns a [ECFParticipantResponse](#ecfparticipantresponse) schema.<br/> | 


### Response examples

200 - The ECF participant being withdrawn
This response returns a [ECFParticipantResponse](#ecfparticipantresponse) schema.

```
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant",
    "attributes": {
      "full_name": "Jane Smith",
      "teacher_reference_number": "1234567",
      "updated_at": "2021-05-31T02:22:32.000Z",
      "ecf_enrolments": [
        {
          "training_record_id": "000a97ff-d2a9-4779-a397-9bfd9063072e",
          "email": "jane.smith@some-school.example.com",
          "mentor_id": "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
          "school_urn": "106286",
          "participant_type": "ect",
          "cohort": "2021",
          "training_status": "withdrawn",
          "participant_status": "withdrawn",
          "teacher_reference_number_validated": true,
          "eligible_for_funding": true,
          "pupil_premium_uplift": true,
          "sparsity_uplift": true,
          "schedule_identifier": "ecf-standard-january",
          "delivery_partner_id": "cd3a12347-7308-4879-942a-c4a70ced400a",
          "withdrawal": {
            "reason": "other",
            "date": "2021-06-31T02:22:32.000Z"
          },
          "deferral": null,
          "created_at": "2022-11-09T16:07:38Z",
          "induction_end_date": "2022-01-12",
          "mentor_funding_end_date": "2021-04-19",
          "cohort_changed_after_payments_frozen": false,
          "mentor_ineligible_for_funding_reason": null
        }
      ],
      "participant_id_changes": [
        {
          "from_participant_id": "23dd8d66-e11f-4139-9001-86b4f9abcb02",
          "to_participant_id": "db3a7848-7308-4879-942a-c4a70ced400a",
          "changed_at": "2023-09-23T02:22:32.000Z"
        }
      ]
    }
  }
}
```


---


## GET /api/v3/participants/ecf/{id}/transfers


 _Note, this endpoint is new.Get a single participant’s transfers_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The ID of the ECF participant.<br/> | 28c461ee-ffc0-4e56-96bd-788579a0ed75 | 


### Responses


| Status | Description |
| ---- | ---- |
| 200 | A single participant’s transfers<br/>This response returns a [ECFParticipantTransferResponse](#ecfparticipanttransferresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.<br/> | 
| 404 | Not Found<br/>This response returns a [NotFoundResponse](#notfoundresponse) schema.<br/> | 


### Response examples

200 - A single participant’s transfers
This response returns a [ECFParticipantTransferResponse](#ecfparticipanttransferresponse) schema.

```
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant-transfer",
    "attributes": {
      "updated_at": "2021-05-31T02:22:32.000Z",
      "transfers": [
        {
          "training_record_id": "000a97ff-d2a9-4779-a397-9bfd9063072e",
          "transfer_type": "new_provider",
          "status": "complete",
          "leaving": null,
          "joining": null,
          "created_at": "2021-05-31T02:22:32.000Z"
        }
      ]
    }
  }
}
```

401 - Unauthorized
This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.

```
{
  "error": "HTTP Token: Access denied"
}
```

404 - Not Found
This response returns a [NotFoundResponse](#notfoundresponse) schema.

```
{
  "title": "string",
  "detail": "string"
}
```


---


## PUT /api/v3/participants/ecf/{id}/change-schedule


 _Note, this endpoint includes updated specifications.Notify that an ECF Participant is changing training schedule_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The ID of the participant<br/> | 28c461ee-ffc0-4e56-96bd-788579a0ed75 | 


### Request body


This consumes a [ECFParticipantChangeScheduleRequest](#ecfparticipantchangeschedulerequest) schema.

### Request example


```
{
  "data": {
    "type": "participant-change-schedule",
    "attributes": {
      "schedule_identifier": "ecf-standard-january",
      "course_identifier": "ecf-mentor",
      "cohort": "2021"
    }
  }
}
```


### Responses


| Status | Description |
| ---- | ---- |
| 200 | The ECF Participant changing schedule<br/>This response returns a [ECFParticipantResponse](#ecfparticipantresponse) schema.<br/> | 


### Response examples

200 - The ECF Participant changing schedule
This response returns a [ECFParticipantResponse](#ecfparticipantresponse) schema.

```
{
  "data": {
    "id": "ac3d1243-7308-4879-942a-c4a70ced400a",
    "type": "participant",
    "attributes": {
      "full_name": "Jane Smith",
      "teacher_reference_number": "1234567",
      "updated_at": "2021-05-31T02:22:32.000Z",
      "ecf_enrolments": [
        {
          "training_record_id": "000a97ff-d2a9-4779-a397-9bfd9063072e",
          "email": "jane.smith@some-school.example.com",
          "mentor_id": "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
          "school_urn": "106286",
          "participant_type": "ect",
          "cohort": "2021",
          "training_status": "active",
          "participant_status": "active",
          "teacher_reference_number_validated": true,
          "eligible_for_funding": true,
          "pupil_premium_uplift": true,
          "sparsity_uplift": true,
          "schedule_identifier": "ecf-standard-january",
          "delivery_partner_id": "cd3a12347-7308-4879-942a-c4a70ced400a",
          "withdrawal": null,
          "deferral": null,
          "created_at": "2021-05-31T02:22:32.000Z",
          "induction_end_date": "2022-01-12",
          "mentor_funding_end_date": "2021-04-19",
          "cohort_changed_after_payments_frozen": true,
          "mentor_ineligible_for_funding_reason": "completed_declaration_received"
        }
      ],
      "participant_id_changes": [
        {
          "from_participant_id": "23dd8d66-e11f-4139-9001-86b4f9abcb02",
          "to_participant_id": "ac3d1243-7308-4879-942a-c4a70ced400a",
          "changed_at": "2021-05-31T02:22:32.000Z"
        }
      ]
    }
  }
}
```


---


## GET /api/v3/unfunded-mentors/ecf


 _Note, this endpoint is new.Retrieve multiple unfunded mentors_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| filter | query | object | false | Refine unfunded mentors to return.<br/>This consumes a [ListFilter](#listfilter) schema.<br/> | filter[updated\_since]=2020-11-13T11:21:55Z | 
| page | query | object | false | Pagination options to navigate through the list of unfunded mentors.<br/>This consumes a [Pagination](#pagination) schema.<br/> | page[page]=1&page[per\_page]=5 | 
| sort | query | array | false | Sort unfunded mentors being returned.<br/>This consumes a [ECFUnfundedMentorsSort](#ecfunfundedmentorssort) schema.<br/> | sort=-updated\_at | 


### Responses


| Status | Description |
| ---- | ---- |
| 200 | A list of unfunded mentors<br/>This response returns a [MultipleUnfundedMentorsResponse](#multipleunfundedmentorsresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.<br/> | 


### Response examples

200 - A list of unfunded mentors
This response returns a [MultipleUnfundedMentorsResponse](#multipleunfundedmentorsresponse) schema.

```
{
  "data": [
    {
      "id": "db3a7848-7308-4879-942a-c4a70ced400a",
      "type": "unfunded-mentor",
      "attributes": {
        "full_name": "Jane Smith",
        "email": "jane.smith@some-school.example.com",
        "teacher_reference_number": "1234567",
        "created_at": "2021-05-31T02:22:32.000Z",
        "updated_at": "2021-05-31T02:22:32.000Z"
      }
    }
  ]
}
```

401 - Unauthorized
This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.

```
{
  "error": "HTTP Token: Access denied"
}
```


---


## GET /api/v3/unfunded-mentors/ecf/{id}


 _Note, this endpoint is new.Get a single unfunded mentor_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The ID of the unfunded mentor.<br/> | 28c461ee-ffc0-4e56-96bd-788579a0ed75 | 


### Responses


| Status | Description |
| ---- | ---- |
| 200 | A single unfunded mentor<br/>This response returns a [UnfundedMentorResponse](#unfundedmentorresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.<br/> | 
| 404 | Not Found<br/>This response returns a [NotFoundResponse](#notfoundresponse) schema.<br/> | 


### Response examples

200 - A single unfunded mentor
This response returns a [UnfundedMentorResponse](#unfundedmentorresponse) schema.

```
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "unfunded-mentor",
    "attributes": {
      "full_name": "Jane Smith",
      "email": "jane.smith@some-school.example.com",
      "teacher_reference_number": "1234567",
      "created_at": "2021-05-31T02:22:32.000Z",
      "updated_at": "2021-05-31T02:22:32.000Z"
    }
  }
}
```

401 - Unauthorized
This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.

```
{
  "error": "HTTP Token: Access denied"
}
```

404 - Not Found
This response returns a [NotFoundResponse](#notfoundresponse) schema.

```
{
  "title": "string",
  "detail": "string"
}
```


---


## GET /api/v3/statements


 _Note, this endpoint is new.Retrieve financial statements_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| filter | query | object | false | Refine statements to return.<br/>This consumes a [StatementsFilter](#statementsfilter) schema.<br/> | filter[cohort]=2021,2022&filter[type]=ecf&filter[updated\_since]=2020-11-13T11:21:55Z | 
| page | query | object | false | Pagination options to navigate through the list of statements.<br/>This consumes a [Pagination](#pagination) schema.<br/> | page[page]=1&page[per\_page]=5 | 


### Responses


| Status | Description |
| ---- | ---- |
| 200 | A list of statements as part of which the DfE will make output payments for ecf participants<br/>This response returns a [StatementsResponse](#statementsresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.<br/> | 


### Response examples

200 - A list of statements as part of which the DfE will make output payments for ecf participants
This response returns a [StatementsResponse](#statementsresponse) schema.

```
{
  "data": [
    {
      "id": "cd3a12347-7308-4879-942a-c4a70ced400a",
      "type": "statement",
      "attributes": {
        "month": "May",
        "year": "2022",
        "type": "ecf",
        "cohort": "2021",
        "cut_off_date": "2022-04-30",
        "payment_date": "2022-05-25",
        "paid": true,
        "created_at": "2021-05-31T02:22:32.000Z",
        "updated_at": "2021-05-31T02:22:32.000Z"
      }
    }
  ]
}
```

401 - Unauthorized
This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.

```
{
  "error": "HTTP Token: Access denied"
}
```


---


## GET /api/v3/statements/{id}


 _Note, this endpoint is new.Retrieve specific financial statement_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The unique ID of the statement<br/> | fe82db5d-a7ff-42b4-9eb7-19a87bf0ce5f | 


### Responses


| Status | Description |
| ---- | ---- |
| 200 | A specific financial statement<br/>This response returns a [StatementResponse](#statementresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.<br/> | 
| 404 | Not Found<br/>This response returns a [NotFoundResponse](#notfoundresponse) schema.<br/> | 


### Response examples

200 - A specific financial statement
This response returns a [StatementResponse](#statementresponse) schema.

```
{
  "data": {
    "id": "cd3a12347-7308-4879-942a-c4a70ced400a",
    "type": "statement",
    "attributes": {
      "month": "May",
      "year": "2022",
      "type": "ecf",
      "cohort": "2021",
      "cut_off_date": "2022-04-30",
      "payment_date": "2022-05-25",
      "paid": true,
      "created_at": "2021-05-31T02:22:32.000Z",
      "updated_at": "2021-05-31T02:22:32.000Z"
    }
  }
}
```

401 - Unauthorized
This response returns a [UnauthorisedResponse](#unauthorisedresponse) schema.

```
{
  "error": "HTTP Token: Access denied"
}
```

404 - Not Found
This response returns a [NotFoundResponse](#notfoundresponse) schema.

```
{
  "title": "string",
  "detail": "string"
}
```


---


## Schemas


### BadOrMissingParametersResponse


Request was missing data or contained invalid data

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| bad\_or\_missing\_parameters | array | true | An error message for each bad or missing attribute describing the problems<br/> | 


### BadRequestResponse


Bad Request

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| bad\_request | string | false | An error message for bad request<br/> | 


#### Example


```
{
  "errors": [
    {
      "title": "Bad request",
      "detail": "correct json data structure required. See API docs for reference"
    }
  ]
}
```


### DeliveryPartner


A delivery partner

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| id | string | true | The unique identifier of the delivery partner<br/> | 
| type | string | true | The data type<br/> | 
| attributes | object | true | The data attributes associated with a delivery partner<br/>It conforms to [DeliveryPartnerAttributes](#deliverypartnerattributes) schema. | 


### DeliveryPartnerAttributes


The data attributes associated with a delivery partner

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| name | string | true | The name of the delivery partner you are working with<br/> | 
| cohort | array | false | The cohorts for which you may report school partnerships with this delivery partner<br/> | 
| created\_at | string | true | The date and time the delivery partner was created<br/> | 
| updated\_at | string | true | The date and time the delivery partner was last updated<br/> | 


### DeliveryPartnerCohortError


Not a delivery partner you have a relationship with for this cohort

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| title | string | false | Title of error message<br/>Possible values:<br/><ul><li>Not a delivery partner you have a relationship with for this cohort</li></ul> | 
| detail | string | false | Additional info on which cohorts are available<br/> | 


### DeliveryPartnerResponse


A delivery partner

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true | A delivery partner<br/>It conforms to [DeliveryPartner](#deliverypartner) schema. | 


### DeliveryPartnersFilter


Filter delivery partners to return more specific results

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| cohort | string | false | Return delivery partners from the specified cohort or cohorts. This is a comma delimited string of years.<br/> | 


### DeliveryPartnersResponse


A list of delivery partners

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | array | true | It conforms to [DeliveryPartner](#deliverypartner) schema. | 


### DeliveryPartnersSort


Sort delivery partners being returned

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| Item | string | false | It conforms to [DeliveryPartnersSort/items](#deliverypartnerssort-items) schema.Possible values:<br/><ul><li>created\_at</li><li>-created\_at</li><li>updated\_at</li><li>-updated\_at</li></ul> | 


### ECFDeferral


The details of an ECF Participant deferral

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| reason | string | true | The reason a participant was deferred<br/>Possible values:<br/><ul><li>bereavement</li><li>long-term-sickness</li><li>parental-leave</li><li>career-break</li><li>other</li></ul> | 
| date | string | true | The date and time the participant was deferred<br/> | 


#### Example


```
{
  "reason": "career-break",
  "date": "2021-05-31T02:22:32.000Z"
}
```


### ECFEnrolment


The details of an ECF Participant enrolment

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| training\_record\_id | string | true | The unique identifier of the participant training record. Should the DfE dedupe a participant, this value will not change.<br/> | 
| email | string | true | The email address registered for this ECF participant<br/> | 
| mentor\_id | string | false | The unique identifier of this ECF participants mentor<br/> | 
| school\_urn | string | true | The Unique Reference Number (URN) of the school that submitted this ECF participant<br/> | 
| participant\_type | string | true | The type of ECF participant this record refers to<br/>Possible values:<br/><ul><li>ect</li><li>mentor</li></ul> | 
| cohort | string | true | Indicates which call-off contract funds this participant’s training. 2021 indicates a participant that has started, or will start, their training in the 2021/22 academic year.<br/> | 
| training\_status | string | true | The training status of the ECF participant<br/>Possible values:<br/><ul><li>active</li><li>deferred</li><li>withdrawn</li></ul> | 
| participant\_status | string | true | Replaces the old status field. Indicates if a SIT has advised DfE of a transfer or a withdrawal of the participant from the school<br/>Possible values:<br/><ul><li>active</li><li>joining</li><li>leaving</li><li>left</li><li>withdrawn</li></ul> | 
| teacher\_reference\_number\_validated | boolean | true | Indicates whether the Teacher Reference Number (TRN) has been validated<br/> | 
| eligible\_for\_funding | boolean | true | Indicates whether this participant is eligible to receive DfE funded induction<br/> | 
| pupil\_premium\_uplift | boolean | true | Indicates whether this participant qualifies for an uplift payment due to pupil premium<br/> | 
| sparsity\_uplift | boolean | true | Indicates whether this participant qualifies for an uplift payment due to sparsity<br/> | 
| schedule\_identifier | string | true | The schedule of the ECF participant. For the possible values please refer to the [ECF schedules and milestone dates guidance](/api-reference/ecf/schedules-and-milestone-dates.html#schedules-and-milestone-dates) .<br/>Possible values:<br/><ul><li>ecf-standard-september</li><li>ecf-standard-january</li><li>ecf-standard-april</li><li>ecf-reduced-september</li><li>ecf-reduced-january</li><li>ecf-reduced-april</li><li>ecf-extended-september</li><li>ecf-extended-january</li><li>ecf-extended-april</li><li>ecf-replacement-september</li><li>ecf-replacement-january</li><li>ecf-replacement-april</li></ul> | 
| delivery\_partner\_id | string | true | Unique ID of the delivery partner associated with the participant<br/> | 
| withdrawal |  | false | This conforms to any of the following schemas:<br/><ul><li> [ECFWithdrawal](#ecfwithdrawal) </li></ul> | 
| deferral |  | false | This conforms to any of the following schemas:<br/><ul><li> [ECFDeferral](#ecfdeferral) </li></ul> | 
| created\_at | string | true | The date and time the ECF participant was created<br/> | 
| induction\_end\_date | string | false | The ECF participant induction end date<br/> | 
| mentor\_funding\_end\_date | string | false | The ECF participant mentor training completion date<br/> | 
| cohort\_changed\_after\_payments\_frozen | boolean | false | Identify participants that migrated to a new cohort as payments were frozen on their original cohort<br/> | 
| mentor\_ineligible\_for\_funding\_reason | string | false | The reason why funding for a mentor’s training has ended<br/>Possible values:<br/><ul><li>completed\_declaration\_received</li><li>completed\_during\_early\_roll\_out</li><li>started\_not\_completed</li></ul> | 


### ECFParticipant


 **Note, this endpoint includes updated specifications.** The details of a participant

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| id | string | true | The unique identifier of the participant record<br/> | 
| type | string | true | The data type<br/> | 
| attributes | object | true | The data attributes associated with an ECF participant<br/>It conforms to [ECFParticipantAttributes](#ecfparticipantattributes) schema. | 


### ECFParticipantAttributes


The data attributes associated with an ECF participant

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| full\_name | string | true | The full name of this ECF participant<br/> | 
| teacher\_reference\_number | string | false | The Teacher Reference Number (TRN) for this participant<br/> | 
| updated\_at | string | true | The date and time the ECF participant was last updated<br/> | 
| ecf\_enrolments | array | true | Information about the course(s) the participant is enroled in<br/>It conforms to [ECFEnrolment](#ecfenrolment) schema. | 
| participant\_id\_changes | array | true | Information about the Participant ID changes<br/>It conforms to [ParticipantIdChange](#participantidchange) schema. | 


### ECFParticipantChangeSchedule


An ECF participant change schedule action

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| type | string | true | The data type<br/>Possible values:<br/><ul><li>participant-change-schedule</li></ul> | 
| attributes | object | true | An ECF participant change schedule action<br/>It conforms to [ECFParticipantChangeScheduleAttributes](#ecfparticipantchangescheduleattributes) schema. | 


#### Example


```
{
  "type": "participant-change-schedule",
  "attributes": {
    "schedule_identifier": "ecf-standard-january",
    "course_identifier": "ecf-mentor"
  }
}
```


### ECFParticipantChangeScheduleAttributes


An ECF participant change schedule action

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| schedule\_identifier | string | true | The new schedule of the participant<br/>Possible values:<br/><ul><li>ecf-standard-september</li><li>ecf-standard-january</li><li>ecf-standard-april</li><li>ecf-reduced-september</li><li>ecf-reduced-january</li><li>ecf-reduced-april</li><li>ecf-extended-september</li><li>ecf-extended-january</li><li>ecf-extended-april</li><li>ecf-replacement-september</li><li>ecf-replacement-january</li><li>ecf-replacement-april</li></ul> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><ul><li>ecf-induction</li><li>ecf-mentor</li></ul> | 
| cohort | string | false | Providers may not change the current value for ECF participants. Indicates which call-off contract funds this participant’s training. 2021 indicates a participant that has started, or will start, their training in the 2021/22 academic year.<br/> | 


#### Example


```
{
  "schedule_identifier": "ecf-standard-january",
  "course_identifier": "ecf-mentor",
  "cohort": "2021"
}
```


### ECFParticipantChangeScheduleRequest


The change schedule request for a participant

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true | An ECF participant change schedule action<br/>It conforms to [ECFParticipantChangeSchedule](#ecfparticipantchangeschedule) schema. | 


#### Example


```
{
  "data": {
    "type": "participant-change-schedule",
    "attributes": {
      "schedule_identifier": "ecf-standard-january",
      "course_identifier": "ecf-mentor",
      "cohort": "2021"
    }
  }
}
```


### ECFParticipantDeclarationPost2024ECTCompletedAttributesRequest


An ECF completed participant declaration

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| participant\_id | string | true | The unique ID of the participant<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><ul><li>completed</li></ul> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><ul><li>ecf-induction</li></ul> | 
| evidence\_held | string | true | The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.<br/>Possible values:<br/><ul><li>75-percent-engagement-met</li><li>75-percent-engagement-met-reduced-induction</li><li>one-term-induction</li></ul> | 


### ECFParticipantDeclarationPost2024ECTExtendedAttributesRequest


An ECF extended participant declaration

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| participant\_id | string | true | The unique ID of the participant<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><ul><li>extended-1</li><li>extended-2</li><li>extended-3</li></ul> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><ul><li>ecf-induction</li></ul> | 
| evidence\_held | string | true | The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.<br/>Possible values:<br/><ul><li>training-event-attended</li><li>self-study-material-completed</li><li>materials-engaged-with-offline</li><li>other</li></ul> | 


### ECFParticipantDeclarationPost2024ECTRetainedAttributesRequest


An ECF participant retained declaration

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| participant\_id | string | true | The unique ID of the participant<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><ul><li>retained-1</li><li>retained-2</li><li>retained-3</li><li>retained-4</li></ul> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><ul><li>ecf-induction</li></ul> | 
| evidence\_held | string | true | The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period. For retained-2 declarations, providers will need to confirm if the engagement threshold has been reached and only accept either the ‘75-percent-engagement-met’ or ‘75-percent-engagement-met-reduced-induction’ values.<br/>Possible values:<br/><ul><li>training-event-attended</li><li>self-study-material-completed</li><li>materials-engaged-with-offline</li><li>other</li><li>75-percent-engagement-met</li><li>75-percent-engagement-met-reduced-induction</li></ul> | 


### ECFParticipantDeclarationPost2024ECTStartedAttributesRequest


An ECF started participant declaration

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| participant\_id | string | true | The unique ID of the participant<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><ul><li>started</li></ul> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><ul><li>ecf-induction</li></ul> | 
| evidence\_held | string | false | The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.<br/>Possible values:<br/><ul><li>training-event-attended</li><li>self-study-material-completed</li><li>materials-engaged-with-offline</li><li>other</li></ul> | 


### ECFParticipantDeclarationPost2024MentorCompletedAttributesRequest


An ECF completed participant declaration

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| participant\_id | string | true | The unique ID of the participant<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><ul><li>completed</li></ul> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><ul><li>ecf-mentor</li></ul> | 
| evidence\_held | string | true | The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.<br/>Possible values:<br/><ul><li>75-percent-engagement-met</li><li>75-percent-engagement-met-reduced-induction</li></ul> | 


### ECFParticipantDeclarationPost2024MentorStartedAttributesRequest


An ECF started participant declaration

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| participant\_id | string | true | The unique ID of the participant<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><ul><li>started</li></ul> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><ul><li>ecf-mentor</li></ul> | 
| evidence\_held | string | false | The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.<br/>Possible values:<br/><ul><li>training-event-attended</li><li>self-study-material-completed</li><li>materials-engaged-with-offline</li><li>other</li></ul> | 


### ECFParticipantDeclarationPre2025CompletedAttributesRequest


An ECF completed participant declaration

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| participant\_id | string | true | The unique ID of the participant<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><ul><li>completed</li></ul> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><ul><li>ecf-induction</li><li>ecf-mentor</li></ul> | 
| evidence\_held | string | true | The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.<br/>Possible values:<br/><ul><li>training-event-attended</li><li>self-study-material-completed</li><li>other</li></ul> | 


### ECFParticipantDeclarationPre2025ExtendedAttributesRequest


An ECF extended participant declaration

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| participant\_id | string | true | The unique ID of the participant<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><ul><li>extended-1</li><li>extended-2</li><li>extended-3</li></ul> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><ul><li>ecf-induction</li><li>ecf-mentor</li></ul> | 
| evidence\_held | string | true | The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.<br/>Possible values:<br/><ul><li>training-event-attended</li><li>self-study-material-completed</li><li>other</li></ul> | 


### ECFParticipantDeclarationPre2025RetainedAttributesRequest


An ECF participant retained declaration

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| participant\_id | string | true | The unique ID of the participant<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><ul><li>retained-1</li><li>retained-2</li><li>retained-3</li><li>retained-4</li></ul> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><ul><li>ecf-induction</li><li>ecf-mentor</li></ul> | 
| evidence\_held | string | true | The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.<br/>Possible values:<br/><ul><li>training-event-attended</li><li>self-study-material-completed</li><li>other</li></ul> | 


### ECFParticipantDeclarationPre2025StartedAttributesRequest


An ECF started participant declaration

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| participant\_id | string | true | The unique ID of the participant<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><ul><li>started</li></ul> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><ul><li>ecf-induction</li><li>ecf-mentor</li></ul> | 


### ECFParticipantDefer


The details of a participant deferral request

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| type | string | true | The data type<br/>Possible values:<br/><ul><li>participant-defer</li></ul> | 
| attributes | object | true | An ECF participant deferral action<br/>It conforms to [ECFParticipantDeferAttributes](#ecfparticipantdeferattributes) schema. | 


### ECFParticipantDeferAttributes


An ECF participant deferral action

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| reason | string | true | The reason for the deferral<br/>Possible values:<br/><ul><li>bereavement</li><li>long-term-sickness</li><li>parental-leave</li><li>career-break</li><li>other</li></ul> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><ul><li>ecf-induction</li><li>ecf-mentor</li></ul> | 


#### Example


```
{
  "reason": "career-break",
  "course_identifier": "ecf-mentor"
}
```


### ECFParticipantDeferRequest


The deferral request for a participant

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true | The details of a participant deferral request<br/>It conforms to [ECFParticipantDefer](#ecfparticipantdefer) schema. | 


#### Example


```
{
  "data": {
    "type": "participant-defer",
    "attributes": {
      "reason": "career-break",
      "course_identifier": "ecf-mentor"
    }
  }
}
```


### ECFParticipantFilter


Filter a list of records to return more specific results

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| updated\_since | string | false | Return only records that have been updated since this date and time (ISO 8601 date format)<br/> | 
| cohort | string | false | Return only records for the given cohort<br/> | 
| training\_status | string | false | Return only records that have this training status<br/> | 
| from\_participant\_id | string | false | Return only records that have this from Participant ID<br/> | 


### ECFParticipantJoining


The details of an ECF Participant joining a school

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| school\_urn | string | true | The URN of the school the participant is joining<br/> | 
| provider | string | true | The name of the provider the participant is joining<br/> | 
| date | string | true | The date the participant will be joining the school<br/> | 


#### Example


```
{
  "school_urn": 123456,
  "provider": "Example Institute",
  "date": "2021-05-31"
}
```


### ECFParticipantLeaving


The details of an ECF Participant leaving a school

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| school\_urn | string | true | The URN of the school the participant is leaving<br/> | 
| provider | string | true | The name of the provider the participant is leaving<br/> | 
| date | string | false | The date the participant will be leaving the school<br/> | 


#### Example


```
{
  "school_urn": 123456,
  "provider": "Example Institute",
  "date": "2021-05-31"
}
```


### ECFParticipantResponse


An ECF Participant

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true |  **Note, this endpoint includes updated specifications.** The details of a participant<br/>It conforms to [ECFParticipant](#ecfparticipant) schema. | 


### ECFParticipantResume


An ECF participant resume action

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| type | string | true | The data type<br/>Possible values:<br/><ul><li>participant-resume</li></ul> | 
| attributes | object | true | An ECF participant resume action<br/>It conforms to [ECFParticipantResumeAttributes](#ecfparticipantresumeattributes) schema. | 


### ECFParticipantResumeAttributes


An ECF participant resume action

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><ul><li>ecf-induction</li><li>ecf-mentor</li></ul> | 


#### Example


```
{
  "course_identifier": "ecf-mentor"
}
```


### ECFParticipantResumeRequest


The resume request for a participant

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true | An ECF participant resume action<br/>It conforms to [ECFParticipantResume](#ecfparticipantresume) schema. | 


#### Example


```
{
  "data": {
    "type": "participant-resume",
    "attributes": {
      "course_identifier": "ecf-mentor"
    }
  }
}
```


### ECFParticipantTransfer


 **Note, this is a new endpoint.** The details of an ECF participant transfer

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| id | string | true | The unique identifier of the participant record<br/> | 
| type | string | true | The data type<br/> | 
| attributes | object | true | The data attributes associated with an ECF participant transfer<br/>It conforms to [ECFParticipantTransferAttributes](#ecfparticipanttransferattributes) schema. | 


### ECFParticipantTransferAttributes


The data attributes associated with an ECF participant transfer

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| updated\_at | string | true | The date and time the latest ECF participant was last updated<br/> | 
| transfers | array | true | List of participant transfers<br/>It conforms to [ECFParticipantTransfers](#ecfparticipanttransfers) schema. | 


### ECFParticipantTransferResponse


An ECF participant transfer

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true |  **Note, this is a new endpoint.** The details of an ECF participant transfer<br/>It conforms to [ECFParticipantTransfer](#ecfparticipanttransfer) schema. | 


### ECFParticipantTransfers


The details of an ECF Participant enrolment

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| training\_record\_id | string | true | The unique identifier of the participant training record<br/> | 
| transfer\_type | string | true | The type of transfer between schools<br/>Possible values:<br/><ul><li>new\_school</li><li>new\_provider</li><li>unknown</li></ul> | 
| status | string | true | The status of the transfer, if both leaving and joining SIT have completed their journeys or only one has<br/>Possible values:<br/><ul><li>incomplete</li><li>complete</li></ul> | 
| leaving |  | false | This conforms to any of the following schemas:<br/><ul><li> [ECFParticipantLeaving](#ecfparticipantleaving) </li></ul> | 
| joining |  | false | This conforms to any of the following schemas:<br/><ul><li> [ECFParticipantJoining](#ecfparticipantjoining) </li></ul> | 
| created\_at | string | true | The date and time the ECF participant transfer was created<br/> | 


### ECFParticipantWithdraw


An ECF participant withdrawal action

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| type | string | false | The data type<br/>Possible values:<br/><ul><li>participant-withdraw</li></ul> | 
| attributes | object | false | An ECF participant withdrawal action<br/>It conforms to [ECFParticipantWithdrawAttributes](#ecfparticipantwithdrawattributes) schema. | 


### ECFParticipantWithdrawAttributes


An ECF participant withdrawal action

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| reason | string | true | The reason for the withdrawal<br/>Possible values:<br/><ul><li>left-teaching-profession</li><li>moved-school</li><li>mentor-no-longer-being-mentor</li><li>switched-to-school-led</li><li>other</li></ul> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><ul><li>ecf-induction</li><li>ecf-mentor</li></ul> | 


#### Example


```
{
  "reason": "left-teaching-profession",
  "course_identifier": "ecf-mentor"
}
```


### ECFParticipantWithdrawRequest


The withdrawal request for a participant

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true | An ECF participant withdrawal action<br/>It conforms to [ECFParticipantWithdraw](#ecfparticipantwithdraw) schema. | 


#### Example


```
{
  "data": {
    "type": "participant-withdraw",
    "attributes": {
      "reason": "left-teaching-profession",
      "course_identifier": "ecf-mentor"
    }
  }
}
```


### ECFParticipantsSort


Sort ECF participants being returned

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| Item | string | false | It conforms to [ECFParticipantsSort/items](#ecfparticipantssort-items) schema.Possible values:<br/><ul><li>created\_at</li><li>-created\_at</li><li>updated\_at</li><li>-updated\_at</li></ul> | 


### ECFPartnership


An ECF partnership

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| id | string | true | The unique identifier of the partnership<br/> | 
| type | string | true | The data type<br/> | 
| attributes | object | true | The data attributes associated with an ECF partnership<br/>It conforms to [ECFPartnershipAttributes](#ecfpartnershipattributes) schema. | 


### ECFPartnershipAttibutesRequest


| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| cohort | string | true | The cohort for which you are reporting the partnership<br/> | 
| delivery\_partner\_id | string | true | The unique ID of the delivery partner you will work with for this school partnership<br/> | 
| school\_id | string | true | The Unique ID of the school you are partnering with<br/> | 


### ECFPartnershipAttributes


The data attributes associated with an ECF partnership

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| cohort | string | true | The cohort for which you are reporting the partnership<br/> | 
| urn | string | true | The Unique Reference Number (URN) of the school you are partnered with<br/> | 
| school\_id | string | true | The unique ID of the school you are partnered with<br/> | 
| delivery\_partner\_id | string | true | The unique ID of the delivery partner you are working with for this partnership<br/> | 
| delivery\_partner\_name | string | false | The name of the delivery partner you are working with for this partnership<br/> | 
| status | string | true | The status of the partnership which includes active or challenged<br/>Possible values:<br/><ul><li>active</li><li>challenged</li></ul> | 
| challenged\_reason | string | false | If the partnership has been challenged, the reason provided for the challenge by the SIT<br/>Possible values:<br/><ul><li>another\_provider</li><li>not\_confirmed</li><li>do\_not\_recognise</li><li>no\_ects</li><li>mistake</li></ul> | 
| challenged\_at | string | false | The date the partnership has been challenged<br/> | 
| induction\_tutor\_name | string | false | The name of the induction tutor at the school you are in partnership with<br/> | 
| induction\_tutor\_email | string | false | The email address of the induction tutor at the school you are in partnership with<br/> | 
| updated\_at | string | true | The date the partnership was last updated<br/> | 
| created\_at | string | true | The date the partnership was reported by you<br/> | 


### ECFPartnershipDataRequest


An ECF partnership

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| type | string | false | Possible values:<br/><ul><li>ecf-partnership</li></ul> | 
| attributes | object | false | It conforms to [ECFPartnershipAttibutesRequest](#ecfpartnershipattibutesrequest) schema. | 


### ECFPartnershipRequest


An ECF partnership

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true | An ECF partnership<br/>It conforms to [ECFPartnershipDataRequest](#ecfpartnershipdatarequest) schema. | 


#### Example


```
{
  "data": {
    "type": "ecf-partnership",
    "attributes": {
      "cohort": "2021",
      "school_id": "24b61d1c-ad95-4000-aee0-afbdd542294a",
      "delivery_partner_id": "db2fbf67-b7b7-454f-a1b7-0020411e2314"
    }
  }
}
```


### ECFPartnershipRequestErrorResponse


A list of errors

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| error | array | false | This conforms to any of the following schemas:<br/><ul><li> [UrnInvalidError](#urninvaliderror) </li><li> [PartnershipExistsError](#partnershipexistserror) </li><li> [SchoolFundingError](#schoolfundingerror) </li><li> [DeliveryPartnerCohortError](#deliverypartnercohorterror) </li><li> [OtherProviderRecruitedError](#otherproviderrecruitederror) </li></ul> | 


### ECFPartnershipResponse


An ECF partnership

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true | An ECF partnership<br/>It conforms to [ECFPartnership](#ecfpartnership) schema. | 


### ECFPartnershipUpdateAttibutesRequest


| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| delivery\_partner\_id | string | true | The unique ID of the delivery partner you will work with for this school partnership<br/> | 


### ECFPartnershipUpdateDataRequest


Update An ECF partnership

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| type | string | false | Possible values:<br/><ul><li>ecf-partnership-update</li></ul> | 
| attributes | object | false | It conforms to [ECFPartnershipUpdateAttibutesRequest](#ecfpartnershipupdateattibutesrequest) schema. | 


### ECFPartnershipUpdateRequest


Update an ECF partnership

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true | Update An ECF partnership<br/>It conforms to [ECFPartnershipUpdateDataRequest](#ecfpartnershipupdatedatarequest) schema. | 


#### Example


```
{
  "data": {
    "type": "ecf-partnership-update",
    "attributes": {
      "delivery_partner_id": "db2fbf67-b7b7-454f-a1b7-0020411e2314"
    }
  }
}
```


### ECFSchool


An ECF school

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| id | string | true | The unique identifier of the school<br/> | 
| type | string | true | The data type<br/> | 
| attributes | object | true | The data attributes associated with an ECF school<br/>It conforms to [ECFSchoolAttributes](#ecfschoolattributes) schema. | 


### ECFSchoolAttributes


The data attributes associated with an ECF school

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| name | string | true | The name of the school<br/> | 
| urn | string | true | The Unique Reference Number (URN) of the school<br/> | 
| cohort | string | true | Indicates which call-off contract funds this participant’s training. 2021 indicates a participant that has started, or will start, their training in the 2021/22 academic year.<br/> | 
| in\_partnership | boolean | true | Whether or not the school already has an active partnership, if it is doing a funded induction programme<br/> | 
| induction\_programme\_choice | string | true | The induction programme the school offers<br/>Possible values:<br/><ul><li>school\_led</li><li>provider\_led</li><li>no\_early\_career\_teachers</li><li>not\_yet\_known</li></ul> | 
| created\_at | string | true | The date and time the school was created<br/> | 
| updated\_at | string | true | The last time a change was made to this school record by the DfE<br/> | 


### ECFSchoolResponse


A single ECF school

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true | An ECF school<br/>It conforms to [ECFSchool](#ecfschool) schema. | 


### ECFSchoolsFilter


Filter schools to return more specific results

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| cohort | string | false | Return schools within the specified cohort.<br/> | 
| urn | string | false | Return a school with the specified Unique Reference Number (URN).<br/> | 
| updated\_since | string | false | Return only records that have been updated since this date and time (ISO 8601 date format)<br/> | 


### ECFSchoolsSort


Sort schools being returned

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| Item | string | false | It conforms to [ECFSchoolsSort/items](#ecfschoolssort-items) schema.Possible values:<br/><ul><li>updated\_at</li><li>-updated\_at</li></ul> | 


### ECFUnfundedMentorsSort


Sort unfunded mentors being returned.

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| Item | string | false | It conforms to [ECFUnfundedMentorsSort/items](#ecfunfundedmentorssort-items) schema.Possible values:<br/><ul><li>updated\_at</li><li>-updated\_at</li></ul> | 


### ECFWithdrawal


The details of an ECF Participant withdrawal

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| reason | string | true | The reason a participant was withdrawn<br/>Possible values:<br/><ul><li>left-teaching-profession</li><li>moved-school</li><li>mentor-no-longer-being-mentor</li><li>switched-to-school-led</li><li>other</li></ul> | 
| date | string | true | The date and time the participant was withdrawn<br/> | 


#### Example


```
{
  "reason": "moved-school",
  "date": "2021-05-31T02:22:32.000Z"
}
```


### Error


An single error element

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| title | string | false | A title of the error<br/> | 
| detail | string | false | Additional details of the error<br/> | 


### ErrorResponse


A list of errors

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| error | array | false | It conforms to [Error](#error) schema. | 


### ListFilter


Filter a list of records to return more specific results

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| updated\_since | string | false | Return only records that have been updated since this date and time (ISO 8601 date format)<br/> | 


### ListFilterDeclarations


Filter a list of declarations records to return more specific results

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| updated\_since | string | false | Return only records that have been updated since this date and time (ISO 8601 date format)<br/> | 
| participant\_id | string | false | The unique id of the participant<br/> | 


### MultipleECFParticipantTransferResponse


A list of ECF participant transfers

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | array | true | It conforms to [ECFParticipantTransfer](#ecfparticipanttransfer) schema. | 


### MultipleECFParticipantsResponse


A list of ECF participants

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | array | true | It conforms to [ECFParticipant](#ecfparticipant) schema. | 


### MultipleECFPartnershipsResponse


A list of ECF partnerships

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | array | true | It conforms to [ECFPartnership](#ecfpartnership) schema. | 


### MultipleECFSchoolsResponse


A list of schools for the given cohort

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | array | true | It conforms to [ECFSchool](#ecfschool) schema. | 


### MultipleParticipantDeclarationsResponse


A list of participant declarations

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | array | true | It conforms to [ParticipantDeclarationResponse](#participantdeclarationresponse) schema. | 


### MultipleUnfundedMentorsResponse


A list of unfunded mentors

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | array | true | It conforms to [UnfundedMentor](#unfundedmentor) schema. | 


### NotFoundResponse


The requested resource was not found

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| title | string | false | The title of the error message<br/> | 
| detail | string | false | Further information regarding the error<br/> | 


#### Example


```
{
  "errors": [
    {
      "title": "The requested resource was not found",
      "detail": "Nothing could be found for the provided details"
    }
  ]
}
```


### OtherProviderRecruitedError


Recruited by other provider

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| title | string | false | Title of error message<br/>Possible values:<br/><ul><li>Recruited by other provider</li></ul> | 
| detail | string | false | Additional info<br/> | 


### Pagination


This schema used to paginate through a collection.

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| page | integer | false | The page number to paginate to in the collection. If no value is specified it defaults to the first page.<br/> | 
| per\_page | integer | false | The number items to display on a page. Defaults to 100. Maximum is 3000, if the value is greater that the maximum allowed it will fallback to 3000.<br/> | 


### ParticipantDeclarationAttributes


The data attributes associated with a participant declaration response

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| participant\_id | string | true | The unique id of the participant<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><ul><li>started</li><li>retained-1</li><li>retained-2</li><li>retained-3</li><li>retained-4</li><li>completed</li><li>extended-1</li><li>extended-2</li><li>extended-3</li></ul> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><ul><li>ecf-induction</li><li>ecf-mentor</li></ul> | 
| state | string | true | Indicates the state of this payment declaration<br/>Possible values:<br/><ul><li>submitted</li><li>eligible</li><li>payable</li><li>paid</li><li>voided</li><li>ineligible</li><li>awaiting-clawback</li><li>clawed-back</li></ul> | 
| updated\_at | string | true | The date the declaration was last updated<br/> | 
| created\_at | string | false | The date the declaration was created<br/> | 
| delivery\_partner\_id | string | false | Unique ID of the delivery partner associated with the participant at the time the declaration was created<br/> | 
| statement\_id | string | false | Unique ID of the statement the declaration will be paid as part of<br/> | 
| clawback\_statement\_id | string | false | Unique id of the statement to which the declaration will be clawed back on, if any<br/> | 
| ineligible\_for\_funding\_reason | string | false | If the declaration is ineligible, the reason why<br/>Possible values:<br/><ul><li>duplicate\_declaration</li></ul> | 
| mentor\_id | string | false | Unique ID of the ECT’s mentor<br/> | 
| uplift\_paid | boolean | false | If participant is eligible for uplift, whether it has been paid as part of this declaration<br/> | 
| evidence\_held | string | false | The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period. For retained-2 declarations, providers will need to confirm if the engagement threshold has been reached and only accept either the ‘75-percent-engagement-met’ or ‘75-percent-engagement-met-reduced-induction’ values.<br/>Possible values:<br/><ul><li>training-event-attended</li><li>self-study-material-completed</li><li>other</li><li>materials-engaged-with-offline</li><li>75-percent-engagement-met</li><li>75-percent-engagement-met-reduced-induction</li><li>one-term-induction</li></ul> | 
| has\_passed | boolean | false | Whether the participant has failed or passed<br/> | 
| lead\_provider\_name | string | true | The name of the provider that submitted the declaration<br/> | 


### ParticipantDeclarationPost2024ECTDataRequest


A participant declaration data request for ECT participants from cohort 2025 onwards

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| type | string | false | Possible values:<br/><ul><li>participant-declaration</li></ul> | 
| attributes | object | false | This conforms to any of the following schemas:<br/><ul><li> [ECFParticipantDeclarationPost2024ECTStartedAttributesRequest](#ecfparticipantdeclarationpost2024ectstartedattributesrequest) </li><li> [ECFParticipantDeclarationPost2024ECTRetainedAttributesRequest](#ecfparticipantdeclarationpost2024ectretainedattributesrequest) </li><li> [ECFParticipantDeclarationPost2024ECTCompletedAttributesRequest](#ecfparticipantdeclarationpost2024ectcompletedattributesrequest) </li><li> [ECFParticipantDeclarationPost2024ECTExtendedAttributesRequest](#ecfparticipantdeclarationpost2024ectextendedattributesrequest) </li></ul> | 


### ParticipantDeclarationPost2024MentorDataRequest


A participant declaration data request for mentor participants from cohort 2025 onwards

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| type | string | false | Possible values:<br/><ul><li>participant-declaration</li></ul> | 
| attributes | object | false | This conforms to any of the following schemas:<br/><ul><li> [ECFParticipantDeclarationPost2024MentorStartedAttributesRequest](#ecfparticipantdeclarationpost2024mentorstartedattributesrequest) </li><li> [ECFParticipantDeclarationPost2024MentorCompletedAttributesRequest](#ecfparticipantdeclarationpost2024mentorcompletedattributesrequest) </li></ul> | 


### ParticipantDeclarationPre2025DataRequest


A participant declaration data request for participants in cohort 2024 and previous years

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| type | string | false | Possible values:<br/><ul><li>participant-declaration</li></ul> | 
| attributes | object | false | This conforms to any of the following schemas:<br/><ul><li> [ECFParticipantDeclarationPre2025StartedAttributesRequest](#ecfparticipantdeclarationpre2025startedattributesrequest) </li><li> [ECFParticipantDeclarationPre2025RetainedAttributesRequest](#ecfparticipantdeclarationpre2025retainedattributesrequest) </li><li> [ECFParticipantDeclarationPre2025CompletedAttributesRequest](#ecfparticipantdeclarationpre2025completedattributesrequest) </li><li> [ECFParticipantDeclarationPre2025ExtendedAttributesRequest](#ecfparticipantdeclarationpre2025extendedattributesrequest) </li></ul> | 


### ParticipantDeclarationRequest


An participant declaration request

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true | This conforms to any of the following schemas:<br/><ul><li> [ParticipantDeclarationPre2025DataRequest](#participantdeclarationpre2025datarequest) </li><li> [ParticipantDeclarationPost2024ECTDataRequest](#participantdeclarationpost2024ectdatarequest) </li><li> [ParticipantDeclarationPost2024MentorDataRequest](#participantdeclarationpost2024mentordatarequest) </li></ul> | 


### ParticipantDeclarationResponse


A participant declaration response

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| id | string | true | The unique identifier of the participant declaration record<br/> | 
| type | string | true | The data type<br/> | 
| attributes | object | true | The data attributes associated with a participant declaration response<br/>It conforms to [ParticipantDeclarationAttributes](#participantdeclarationattributes) schema. | 


### ParticipantDeclarationsFilter


Filter participant declarations to return more specific results

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| cohort | string | false | Return participant declarations associated to the specified cohort or cohorts. This is a comma delimited string of years.<br/> | 
| participant\_id | string | false | Return participant declarations associated to the specified participant ID. This is a comma delimited string where multiple participant IDs can be specified<br/> | 
| updated\_since | string | false | Return only records that have been updated since this date and time (ISO 8601 date format)<br/> | 
| delivery\_partner\_id | string | false | Return participant declarations associated to the specified delivery partner or delivery partners. This is a comma delimited string of delivery partner IDs.<br/> | 


### ParticipantIdChange


The details of an Participant ID change

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| from\_participant\_id | string | true | The unique identifier of the changed from participant training record.<br/> | 
| to\_participant\_id | string | true | The unique identifier of the changed to participant training record.<br/> | 
| changed\_at | string | true | The date and time the Participant ID change<br/> | 


#### Example


```
{
  "from_participant_id": "23dd8d66-e11f-4139-9001-86b4f9abcb02",
  "to_participant_id": "ac3d1243-7308-4879-942a-c4a70ced400a",
  "changed_at": "2021-05-31T02:22:32.000Z"
}
```


### PartnershipExistsError


Partnership already exists

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| title | string | false | Title of error message<br/>Possible values:<br/><ul><li>Partnership already exists</li></ul> | 
| detail | string | false | Additional info about existing partnership<br/> | 


### PartnershipsFilter


Filter partnerships to return more specific results

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| cohort | string | false | Return partnerships within the specified cohorts. This is a comma delimited string of years.<br/> | 
| updated\_since | string | false | Return only partnerships that have been updated since this date and time (ISO 8601 date format)<br/> | 
| delivery\_partner\_id | string | false | Return partnerships associated to the specified delivery partner or delivery partners. This is a comma delimited string of delivery partner IDs.<br/> | 


### PartnershipsSort


Sort partnerships being returned

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| Item | string | false | It conforms to [PartnershipsSort/items](#partnershipssort-items) schema.Possible values:<br/><ul><li>created\_at</li><li>-created\_at</li><li>updated\_at</li><li>-updated\_at</li></ul> | 


### SchoolFundingError


The school you have entered has not registered to deliver DfE-funded training. Contact the school for more information.

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| title | string | false | Title of error message<br/>Possible values:<br/><ul><li>The school you have entered has not registered to deliver DfE-funded training. Contact the school for more information.</li></ul> | 
| detail | string | false | Additional info why school is not for DfE-funded training if any<br/> | 


### SingleParticipantDeclarationResponse


A confirmation that the participant declaration has been recorded successfully

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true | A participant declaration response<br/>It conforms to [ParticipantDeclarationResponse](#participantdeclarationresponse) schema. | 


### Statement


A financial statement

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| id | string | true | The unique identifier of the financial statement<br/> | 
| type | string | true | The data type<br/> | 
| attributes | object | true | The data attributes associated with a financial statement<br/>It conforms to [StatementAttributes](#statementattributes) schema. | 


### StatementAttributes


The data attributes associated with a financial statement

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| month | string | false | The month which appears on the statement in the DfE portal<br/> | 
| year | string | false | The calendar year which appears on the statement in the dfe portal<br/> | 
| type | string | false | Type of statement<br/>Possible values:<br/><ul><li>ecf</li></ul> | 
| cohort | string | false | The cohort - 2021 or 2022 - which the statement funds<br/> | 
| cut\_off\_date | string | false | The milestone cut off or review point for the statement<br/> | 
| payment\_date | string | false | The date we expect to pay you for any declarations attached to the statement, which are eligible for payment<br/> | 
| paid | boolean | false | Indicates whether the DfE has paid providers for any declarations attached to the statement<br/> | 
| created\_at | string | false | The date the statement was created<br/> | 
| updated\_at | string | false | The date the statement was last updated<br/> | 


### StatementResponse


A single financial statement

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true | A financial statement<br/>It conforms to [Statement](#statement) schema. | 


### StatementsFilter


Filter statements to return more specific results

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| cohort | string | false | Return statements associated to the specified cohort or cohorts. This is a comma delimited string of years.<br/> | 
| type | string | false | Return statements of a given type<br/>Possible values:<br/><ul><li>ecf</li></ul> | 
| updated\_since | string | false | Return only records that have been updated since this date and time (ISO 8601 date format)<br/> | 


### StatementsResponse


A list of financial statements

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | array | true | It conforms to [Statement](#statement) schema. | 


### UnauthorisedResponse


Authorization information is missing or invalid

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| error | string | false |  | 


### UnfundedMentor


 **Note, this is a new endpoint.** The details of an unfunded mentor

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| id | string | true | The unique identifier of the mentor record<br/> | 
| type | string | true | The data type<br/> | 
| attributes | object | true | The data attributes associated with an unfunded mentor<br/>It conforms to [UnfundedMentorAttributes](#unfundedmentorattributes) schema. | 


### UnfundedMentorAttributes


The data attributes associated with an unfunded mentor

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| full\_name | string | true | The full name of this mentor<br/> | 
| email | string | true | The email address registered for this unfunded mentor<br/> | 
| teacher\_reference\_number | string | false | The Teacher Reference Number (TRN) for this participant<br/> | 
| created\_at | string | true | The date and time the unfunded mentor was created<br/> | 
| updated\_at | string | true | The date and time the unfunded mentor was last updated<br/> | 


### UnfundedMentorResponse


An unfunded mentor

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true |  **Note, this is a new endpoint.** The details of an unfunded mentor<br/>It conforms to [UnfundedMentor](#unfundedmentor) schema. | 


### UrnInvalidError


URN entered is not valid

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| title | string | false | Title of error message<br/>Possible values:<br/><ul><li>URN is not valid</li></ul> | 
| detail | string | false | Additional info why URN is not valid<br/> | 

