
# Lead provider API - 1.0.0


The lead provider API for DfE’s manage teacher CPD service

## Base URLs


 **Sandbox** 
 [https://sb.manage-training-for-early-career-teachers.education.gov.uk](https://sb.manage-training-for-early-career-teachers.education.gov.uk) 
 **Current environment** 
 [/](/) 
 **Production** 
 [https://manage-training-for-early-career-teachers.education.gov.uk](https://manage-training-for-early-career-teachers.education.gov.uk) 
## GET
    
    
      /api/v1/participant-declarations


 _List all participant declarations_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| filter | query | object | false | Refine participant declarations to return.<br/>This consumes a [ListFilterDeclarations](#schema-listfilterdeclarations) schema.<br/> | participant\_id=ab3a7848-1208-7679-942a-b4a70eed400a&updated\_since=2020-11-13T11:21:55Z | 
| page | query | object | false | Pagination options to navigate through the list of participant declarations.<br/>This consumes a [Pagination](#schema-pagination) schema.<br/> | page[page]=1&page[per\_page]=5 | 


### Responses


| Status | Description |
| ---- | ---- |
| 200 | A list of participant declarations<br/>This response returns a [MultipleParticipantDeclarationsResponse](#schema-multipleparticipantdeclarationsresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#schema-unauthorisedresponse) schema.<br/> | 


### Response examples

200 - A list of participant declarations
This response returns a [MultipleParticipantDeclarationsResponse](#schema-multipleparticipantdeclarationsresponse) schema.

```
{
  "data": [
    {
      "id": "01017c12-354b-4b2d-b621-3531ab729c43",
      "type": "participant-declaration",
      "attributes": {
        "participant_id": "db3a7848-7308-4879-942a-c4a70ced400a",
        "declaration_type": "started",
        "declaration_date": "2021-05-31T02:21:32.000Z",
        "course_identifier": "ecf-mentor",
        "eligible_for_payment": false
      }
    },
    {
      "id": "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
      "type": "participant-declaration",
      "attributes": {
        "participant_id": "ab3a7848-7308-4879-942a-c4a70ced400a",
        "declaration_type": "started",
        "declaration_date": "2021-05-31T02:21:32.000Z",
        "course_identifier": "ecf-mentor",
        "eligible_for_payment": true
      }
    }
  ]
}
```

401 - Unauthorized
This response returns a [UnauthorisedResponse](#schema-unauthorisedresponse) schema.

```
{
  "error": "HTTP Token: Access denied"
}
```


---


## POST
    
    
      /api/v1/participant-declarations


 _Declare a participant has reached a milestone. Idempotent endpoint - submitting exact copy of a request will return the same response body as submitting it the first time._ 

### Request body


This consumes a [ParticipantDeclarationRequest](#schema-participantdeclarationrequest) schema.

### Responses


| Status | Description |
| ---- | ---- |
| 200 | Successful<br/>This response returns a [SingleParticipantDeclarationResponse](#schema-singleparticipantdeclarationresponse) schema.<br/> | 
| 422 | Bad or Missing parameter<br/>This response returns a [ErrorResponse](#schema-errorresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#schema-unauthorisedresponse) schema.<br/> | 
| 400 | Bad Request<br/>This response returns a [BadRequestResponse](#schema-badrequestresponse) schema.<br/> | 


### Response examples

200 - Successful
This response returns a [SingleParticipantDeclarationResponse](#schema-singleparticipantdeclarationresponse) schema.

```
{
  "data": {
    "id": "cd3a12347-7308-4879-942a-c4a70ced400a",
    "type": "participant-declaration",
    "attributes": {
      "participant_id": "db3a7848-7308-4879-942a-c4a70ced400a",
      "declaration_type": "started",
      "declaration_date": "2021-05-31T02:21:32.000Z",
      "course_identifier": "ecf-induction",
      "eligible_for_payment": true,
      "voided": true,
      "state": "submitted",
      "updated_at": "2021-05-31T02:22:32.000Z",
      "has_passed": true
    }
  }
}
```

422 - Bad or Missing parameter
This response returns a [ErrorResponse](#schema-errorresponse) schema.

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
This response returns a [UnauthorisedResponse](#schema-unauthorisedresponse) schema.

```
{
  "error": "HTTP Token: Access denied"
}
```

400 - Bad Request
This response returns a [BadRequestResponse](#schema-badrequestresponse) schema.

```
{
  "bad_request": "string"
}
```


---


## GET
    
    
      /api/v1/participant-declarations.csv


 _Retrieve all participant declarations in CSV format_ 

### Responses


| Status | Description |
| ---- | ---- |
| 200 | A CSV file of participant declarations<br/>This response returns a [MultipleParticipantDeclarationsCsvResponse](#schema-multipleparticipantdeclarationscsvresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#schema-unauthorisedresponse) schema.<br/> | 


### Response examples

200 - A CSV file of participant declarations
This response returns a [MultipleParticipantDeclarationsCsvResponse](#schema-multipleparticipantdeclarationscsvresponse) schema.
401 - Unauthorized
This response returns a [UnauthorisedResponse](#schema-unauthorisedresponse) schema.

---


## GET
    
    
      /api/v1/participant-declarations/{id}


 _Get single participant declaration_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The ID of the participant declaration ID<br/> | 9ed4612b-f8bd-44d9-b296-38ab103fadd2 | 


### Responses


| Status | Description |
| ---- | ---- |
| 200 | A single participant declaration<br/>This response returns a [SingleParticipantDeclarationResponse](#schema-singleparticipantdeclarationresponse) schema.<br/> | 
| 404 | Not found<br/>This response returns a [NotFoundResponse](#schema-notfoundresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#schema-unauthorisedresponse) schema.<br/> | 


### Response examples

200 - A single participant declaration
This response returns a [SingleParticipantDeclarationResponse](#schema-singleparticipantdeclarationresponse) schema.

```
{
  "data": {
    "id": "cd3a12347-7308-4879-942a-c4a70ced400a",
    "type": "participant-declaration",
    "attributes": {
      "participant_id": "db3a7848-7308-4879-942a-c4a70ced400a",
      "declaration_type": "started",
      "declaration_date": "2021-05-31T02:21:32.000Z",
      "course_identifier": "ecf-induction",
      "eligible_for_payment": true,
      "voided": true,
      "state": "submitted",
      "updated_at": "2021-05-31T02:22:32.000Z",
      "has_passed": true
    }
  }
}
```

404 - Not found
This response returns a [NotFoundResponse](#schema-notfoundresponse) schema.

```
{
  "error": "Resource not found"
}
```

401 - Unauthorized
This response returns a [UnauthorisedResponse](#schema-unauthorisedresponse) schema.

```
{
  "error": "HTTP Token: Access denied"
}
```


---


## PUT
    
    
      /api/v1/participant-declarations/{id}/void


 _Void a declaration - it will not be soft-deleted_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The ID of the declaration to void<br/> | 28c461ee-ffc0-4e56-96bd-788579a0ed75 | 


### Responses


| Status | Description |
| ---- | ---- |
| 200 | Successful<br/>This response returns a [SingleParticipantDeclarationResponse](#schema-singleparticipantdeclarationresponse) schema.<br/> | 


### Response examples

200 - Successful
This response returns a [SingleParticipantDeclarationResponse](#schema-singleparticipantdeclarationresponse) schema.

```
{
  "data": {
    "id": "cd3a12347-7308-4879-942a-c4a70ced400a",
    "type": "participant-declaration",
    "attributes": {
      "participant_id": "db3a7848-7308-4879-942a-c4a70ced400a",
      "declaration_type": "started",
      "declaration_date": "2021-05-31T02:21:32.000Z",
      "course_identifier": "ecf-induction",
      "eligible_for_payment": true,
      "voided": true,
      "state": "submitted",
      "updated_at": "2021-05-31T02:22:32.000Z",
      "has_passed": true
    }
  }
}
```


---


## GET
    
    
      /api/v1/participants/ecf


 _Retrieve multiple participants, replaces /api/v1/participants_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| filter | query | object | false | Refine ECF participants to return.<br/>This consumes a [ParticipantListFilter](#schema-participantlistfilter) schema.<br/> | filter[cohort]=2022&filter[updated\_since]=2020-11-13T11:21:55Z | 
| page | query | object | false | Pagination options to navigate through the list of ECF participants.<br/>This consumes a [Pagination](#schema-pagination) schema.<br/> | page[page]=1&page[per\_page]=5 | 


### Responses


| Status | Description |
| ---- | ---- |
| 200 | A list of ECF participants<br/>This response returns a [MultipleECFParticipantsResponse](#schema-multipleecfparticipantsresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#schema-unauthorisedresponse) schema.<br/> | 


### Response examples

200 - A list of ECF participants
This response returns a [MultipleECFParticipantsResponse](#schema-multipleecfparticipantsresponse) schema.

```
{
  "data": [
    {
      "id": "db3a7848-7308-4879-942a-c4a70ced400a",
      "type": "participant",
      "attributes": {
        "email": "jane.smith@some-school.example.com",
        "full_name": "Jane Smith",
        "mentor_id": "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
        "school_urn": "106286",
        "participant_type": "ect",
        "cohort": "2021",
        "status": "active",
        "teacher_reference_number": "0012345",
        "teacher_reference_number_validated": true,
        "eligible_for_funding": true,
        "pupil_premium_uplift": false,
        "sparsity_uplift": true,
        "training_status": "active",
        "updated_at": "2021-05-31T02:22:32.000Z"
      }
    },
    {
      "id": "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
      "type": "participant",
      "attributes": {
        "email": "martin.jones@some-school.example.com",
        "full_name": "Martin jones",
        "school_urn": "106286",
        "participant_type": "mentor",
        "cohort": "2021",
        "status": "active",
        "teacher_reference_number": null,
        "teacher_reference_number_validated": false,
        "eligible_for_funding": null,
        "pupil_premium_uplift": true,
        "sparsity_uplift": false,
        "training_status": "deferred",
        "updated_at": "2021-05-31T02:22:32.000Z"
      }
    },
    {
      "id": "eb475531-bf08-48ae-b0ef-c2ff5e5bdef0",
      "type": "participant",
      "attributes": {
        "email": "null,",
        "full_name": null,
        "mentor_id": null,
        "school_urn": null,
        "participant_type": null,
        "cohort": null,
        "status": "withdrawn",
        "teacher_reference_number": null,
        "teacher_reference_number_validated": null,
        "eligible_for_funding": null,
        "pupil_premium_uplift": null,
        "sparsity_uplift": null,
        "training_status": "withdrawn",
        "updated_at": "2021-05-31T02:22:32.000Z"
      }
    }
  ]
}
```

401 - Unauthorized
This response returns a [UnauthorisedResponse](#schema-unauthorisedresponse) schema.

```
{
  "error": "HTTP Token: Access denied"
}
```


---


## GET
    
    
      /api/v1/participants/ecf.csv


 _Retrieve all participants in CSV format, replaces /api/v1/participants.csv_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| filter | query | object | false | Refine ECF participants to return.<br/>This consumes a [ParticipantListFilter](#schema-participantlistfilter) schema.<br/> | updated\_since=2020-11-13T11:21:55Z | 


### Responses


| Status | Description |
| ---- | ---- |
| 200 | A CSV file of ECF participants<br/>This response returns a [MultipleECFParticipantsCsvResponse](#schema-multipleecfparticipantscsvresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#schema-unauthorisedresponse) schema.<br/> | 


### Response examples

200 - A CSV file of ECF participants
This response returns a [MultipleECFParticipantsCsvResponse](#schema-multipleecfparticipantscsvresponse) schema.
401 - Unauthorized
This response returns a [UnauthorisedResponse](#schema-unauthorisedresponse) schema.

---


## GET
    
    
      /api/v1/participants/ecf/{id}


 _Get a single ECF participant_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The ID of the ECF participant.<br/> | 28c461ee-ffc0-4e56-96bd-788579a0ed75 | 


### Responses


| Status | Description |
| ---- | ---- |
| 200 | A single ECF participant<br/>This response returns a [ECFParticipantResponse](#schema-ecfparticipantresponse) schema.<br/> | 
| 401 | Unauthorized<br/>This response returns a [UnauthorisedResponse](#schema-unauthorisedresponse) schema.<br/> | 


### Response examples

200 - A single ECF participant
This response returns a [ECFParticipantResponse](#schema-ecfparticipantresponse) schema.

```
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant",
    "attributes": {
      "email": "jane.smith@some-school.example.com",
      "full_name": "Jane Smith",
      "mentor_id": "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
      "school_urn": "106286",
      "participant_type": "ect",
      "cohort": "2021",
      "status": "active",
      "teacher_reference_number": "1234567",
      "teacher_reference_number_validated": true,
      "eligible_for_funding": true,
      "pupil_premium_uplift": true,
      "sparsity_uplift": true,
      "training_status": "active",
      "training_record_id": "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
      "schedule_identifier": "ecf-standard-january",
      "updated_at": "2021-05-31T02:22:32.000Z"
    }
  }
}
```

401 - Unauthorized
This response returns a [UnauthorisedResponse](#schema-unauthorisedresponse) schema.

```
{
  "error": "HTTP Token: Access denied"
}
```


---


## PUT
    
    
      /api/v1/participants/{id}/defer


 _Notify that an ECF participant is taking a break from their course_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The ID of the participant to defer<br/> | 28c461ee-ffc0-4e56-96bd-788579a0ed75 | 


### Request body


This consumes a [ECFParticipantDeferRequest](#schema-ecfparticipantdeferrequest) schema.

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
| 200 | The ECF participant being deferred<br/>This response returns a [ECFParticipantResponse](#schema-ecfparticipantresponse) schema.<br/> | 


### Response examples

200 - The ECF participant being deferred
This response returns a [ECFParticipantResponse](#schema-ecfparticipantresponse) schema.

```
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant",
    "attributes": {
      "email": "jane.smith@some-school.example.com",
      "full_name": "Jane Smith",
      "mentor_id": "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
      "school_urn": "106286",
      "participant_type": "ect",
      "cohort": "2021",
      "status": "active",
      "teacher_reference_number": "1234567",
      "teacher_reference_number_validated": true,
      "eligible_for_funding": true,
      "pupil_premium_uplift": true,
      "sparsity_uplift": true,
      "training_status": "active",
      "training_record_id": "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
      "schedule_identifier": "ecf-standard-january",
      "updated_at": "2021-05-31T02:22:32.000Z"
    }
  }
}
```


---


## PUT
    
    
      /api/v1/participants/{id}/resume


 _Notify that an ECF participant is resuming their course_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The ID of the participant to resume<br/> | 28c461ee-ffc0-4e56-96bd-788579a0ed75 | 


### Request body


This consumes a [ECFParticipantResumeRequest](#schema-ecfparticipantresumerequest) schema.

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
| 200 | The ECF participant being resumed<br/>This response returns a [ECFParticipantResponse](#schema-ecfparticipantresponse) schema.<br/> | 


### Response examples

200 - The ECF participant being resumed
This response returns a [ECFParticipantResponse](#schema-ecfparticipantresponse) schema.

```
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant",
    "attributes": {
      "email": "jane.smith@some-school.example.com",
      "full_name": "Jane Smith",
      "mentor_id": "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
      "school_urn": "106286",
      "participant_type": "ect",
      "cohort": "2021",
      "status": "active",
      "teacher_reference_number": "1234567",
      "teacher_reference_number_validated": true,
      "eligible_for_funding": true,
      "pupil_premium_uplift": true,
      "sparsity_uplift": true,
      "training_status": "active",
      "training_record_id": "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
      "schedule_identifier": "ecf-standard-january",
      "updated_at": "2021-05-31T02:22:32.000Z"
    }
  }
}
```


---


## PUT
    
    
      /api/v1/participants/{id}/withdraw


 _Notify that an ECF participant has withdrawn from their course_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The ID of the participant to withdraw<br/> | 28c461ee-ffc0-4e56-96bd-788579a0ed75 | 


### Request body


This consumes a [ECFParticipantWithdrawRequest](#schema-ecfparticipantwithdrawrequest) schema.

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
| 200 | The ECF participant being withdrawn<br/>This response returns a [ECFParticipantResponse](#schema-ecfparticipantresponse) schema.<br/> | 


### Response examples

200 - The ECF participant being withdrawn
This response returns a [ECFParticipantResponse](#schema-ecfparticipantresponse) schema.

```
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant",
    "attributes": {
      "email": "jane.smith@some-school.example.com",
      "full_name": "Jane Smith",
      "mentor_id": "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
      "school_urn": "106286",
      "participant_type": "ect",
      "cohort": "2021",
      "status": "active",
      "teacher_reference_number": "1234567",
      "teacher_reference_number_validated": true,
      "eligible_for_funding": true,
      "pupil_premium_uplift": true,
      "sparsity_uplift": true,
      "training_status": "active",
      "training_record_id": "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
      "schedule_identifier": "ecf-standard-january",
      "updated_at": "2021-05-31T02:22:32.000Z"
    }
  }
}
```


---


## PUT
    
    
      /api/v1/participants/ecf/{id}/defer


 _Notify that an ECF participant is taking a break from their course_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The ID of the participant to defer<br/> | 28c461ee-ffc0-4e56-96bd-788579a0ed75 | 


### Request body


This consumes a [ECFParticipantDeferRequest](#schema-ecfparticipantdeferrequest) schema.

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
| 200 | The ECF participant being deferred<br/>This response returns a [ECFParticipantDeferResponse](#schema-ecfparticipantdeferresponse) schema.<br/> | 


### Response examples

200 - The ECF participant being deferred
This response returns a [ECFParticipantDeferResponse](#schema-ecfparticipantdeferresponse) schema.

```
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant",
    "attributes": {
      "email": "jane.smith@some-school.example.com",
      "full_name": "Jane Smith",
      "mentor_id": "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
      "school_urn": "106286",
      "participant_type": "ect",
      "cohort": "2021",
      "status": "active",
      "teacher_reference_number": "1234567",
      "teacher_reference_number_validated": true,
      "eligible_for_funding": true,
      "pupil_premium_uplift": true,
      "sparsity_uplift": true,
      "training_status": "deferred",
      "schedule_identifier": "ecf-standard-january",
      "updated_at": "2021-05-31T02:22:32.000Z"
    }
  }
}
```


---


## PUT
    
    
      /api/v1/participants/ecf/{id}/resume


 _Notify that an ECF participant is resuming their course_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The ID of the participant to resume<br/> | 28c461ee-ffc0-4e56-96bd-788579a0ed75 | 


### Request body


This consumes a [ECFParticipantResumeRequest](#schema-ecfparticipantresumerequest) schema.

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
| 200 | The ECF participant being resumed<br/>This response returns a [ECFParticipantResumeResponse](#schema-ecfparticipantresumeresponse) schema.<br/> | 


### Response examples

200 - The ECF participant being resumed
This response returns a [ECFParticipantResumeResponse](#schema-ecfparticipantresumeresponse) schema.

```
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant",
    "attributes": {
      "email": "jane.smith@some-school.example.com",
      "full_name": "Jane Smith",
      "mentor_id": "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
      "school_urn": "106286",
      "participant_type": "ect",
      "cohort": "2021",
      "status": "active",
      "teacher_reference_number": "1234567",
      "teacher_reference_number_validated": true,
      "eligible_for_funding": true,
      "pupil_premium_uplift": true,
      "sparsity_uplift": true,
      "training_status": "active",
      "schedule_identifier": "ecf-standard-january",
      "updated_at": "2021-05-31T02:22:32.000Z"
    }
  }
}
```


---


## PUT
    
    
      /api/v1/participants/ecf/{id}/withdraw


 _Notify that an ECF participant has withdrawn from their course_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The ID of the participant to withdraw<br/> | 28c461ee-ffc0-4e56-96bd-788579a0ed75 | 


### Request body


This consumes a [ECFParticipantWithdrawRequest](#schema-ecfparticipantwithdrawrequest) schema.

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
| 200 | The ECF participant being withdrawn<br/>This response returns a [ECFParticipantWithdrawResponse](#schema-ecfparticipantwithdrawresponse) schema.<br/> | 


### Response examples

200 - The ECF participant being withdrawn
This response returns a [ECFParticipantWithdrawResponse](#schema-ecfparticipantwithdrawresponse) schema.

```
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant",
    "attributes": {
      "email": "jane.smith@some-school.example.com",
      "full_name": "Jane Smith",
      "mentor_id": "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
      "school_urn": "106286",
      "participant_type": "ect",
      "cohort": "2021",
      "status": "active",
      "teacher_reference_number": "1234567",
      "teacher_reference_number_validated": true,
      "eligible_for_funding": true,
      "pupil_premium_uplift": true,
      "sparsity_uplift": true,
      "training_status": "withdrawn",
      "schedule_identifier": "ecf-standard-january",
      "updated_at": "2021-05-31T02:22:32.000Z"
    }
  }
}
```


---


## PUT
    
    
      /api/v1/participants/{id}/change-schedule


 _Notify that an ECF participant is changing training schedule_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The ID of the participant<br/> | 28c461ee-ffc0-4e56-96bd-788579a0ed75 | 


### Request body


This consumes a [ECFParticipantChangeScheduleRequest](#schema-ecfparticipantchangeschedulerequest) schema.

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
| 200 | The ECF participant changing schedule<br/>This response returns a [ECFParticipantResponse](#schema-ecfparticipantresponse) schema.<br/> | 


### Response examples

200 - The ECF participant changing schedule
This response returns a [ECFParticipantResponse](#schema-ecfparticipantresponse) schema.

```
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant",
    "attributes": {
      "email": "jane.smith@some-school.example.com",
      "full_name": "Jane Smith",
      "mentor_id": "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
      "school_urn": "106286",
      "participant_type": "ect",
      "cohort": "2021",
      "status": "active",
      "teacher_reference_number": "1234567",
      "teacher_reference_number_validated": true,
      "eligible_for_funding": true,
      "pupil_premium_uplift": true,
      "sparsity_uplift": true,
      "training_status": "active",
      "training_record_id": "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
      "schedule_identifier": "ecf-standard-january",
      "updated_at": "2021-05-31T02:22:32.000Z"
    }
  }
}
```


---


## PUT
    
    
      /api/v1/participants/ecf/{id}/change-schedule


 _Notify that an ECF participant is changing training schedule_ 

### Parameters


| Parameter | In | Type | Required | Description | Example |
| ---- | ---- | ---- | ---- | ---- | ---- |
| id | path | string | true | The ID of the participant<br/> | 28c461ee-ffc0-4e56-96bd-788579a0ed75 | 


### Request body


This consumes a [ECFParticipantChangeScheduleRequest](#schema-ecfparticipantchangeschedulerequest) schema.

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
| 200 | The ECF participant changing schedule<br/>This response returns a [ECFParticipantResponse](#schema-ecfparticipantresponse) schema.<br/> | 


### Response examples

200 - The ECF participant changing schedule
This response returns a [ECFParticipantResponse](#schema-ecfparticipantresponse) schema.

```
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant",
    "attributes": {
      "email": "jane.smith@some-school.example.com",
      "full_name": "Jane Smith",
      "mentor_id": "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
      "school_urn": "106286",
      "participant_type": "ect",
      "cohort": "2021",
      "status": "active",
      "teacher_reference_number": "1234567",
      "teacher_reference_number_validated": true,
      "eligible_for_funding": true,
      "pupil_premium_uplift": true,
      "sparsity_uplift": true,
      "training_status": "active",
      "training_record_id": "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
      "schedule_identifier": "ecf-standard-january",
      "updated_at": "2021-05-31T02:22:32.000Z"
    }
  }
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


### ECFParticipant


The details of a participant

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| id | string | true | The unique identifier of the participant record<br/> | 
| type | string | true | The data type<br/> | 
| attributes | object | true | The data attributes associated with an ECF participant<br/>It conforms to [ECFParticipantAttributes](#schema-ecfparticipantattributes) schema. | 


### ECFParticipantAttributes


The data attributes associated with an ECF participant

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| email | string | true | The email address registered for this ECF participant<br/> | 
| full\_name | string | true | The full name of this ECF participant<br/> | 
| mentor\_id | string | false | The unique identifier of this ECF participants mentor<br/> | 
| school\_urn | string | true | The Unique Reference Number (URN) of the school that submitted this ECF participant<br/> | 
| participant\_type | string | true | The type of ECF participant this record refers to<br/>Possible values:<br/><br/> - ect<br/> - mentor<br/><br/> | 
| cohort | string | true | Indicates which call-off contract funds this participant’s training. 2021 indicates a participant that has started, or will start, their training in the 2021/22 academic year.<br/> | 
| status | string | true | The status of this ECF participant record<br/>Possible values:<br/><br/> - active<br/> - withdrawn<br/><br/> | 
| teacher\_reference\_number | string | false | The Teacher Reference Number (TRN) for this ECF participant<br/> | 
| teacher\_reference\_number\_validated | boolean | false | Indicates whether the Teacher Reference Number (TRN) has been validated<br/> | 
| eligible\_for\_funding | boolean | false | Indicates whether this participant is eligible to receive DfE funded induction<br/> | 
| pupil\_premium\_uplift | boolean | false | Indicates whether this participant qualifies for an uplift payment due to pupil premium<br/> | 
| sparsity\_uplift | boolean | false | Indicates whether this participant qualifies for an uplift payment due to sparsity<br/> | 
| training\_status | string | true | The training status of the ECF participant<br/>Possible values:<br/><br/> - active<br/> - deferred<br/> - withdrawn<br/><br/> | 
| training\_record\_id | string | true | The unique identifier of the participant training record<br/> | 
| schedule\_identifier | string | true | The schedule of the ECF participant<br/>Possible values:<br/><br/> - ecf-standard-september<br/> - ecf-standard-january<br/> - ecf-standard-april<br/> - ecf-reduced-september<br/> - ecf-reduced-january<br/> - ecf-reduced-april<br/> - ecf-extended-september<br/> - ecf-extended-january<br/> - ecf-extended-april<br/> - ecf-replacement-september<br/> - ecf-replacement-january<br/> - ecf-replacement-april<br/><br/> | 
| updated\_at | string | true | The date the ECF participant was last updated<br/> | 


### ECFParticipantChangeSchedule


An ECF participant change schedule action

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| type | string | true | The data type<br/>Possible values:<br/><br/> - participant-change-schedule<br/><br/> | 
| attributes | object | true | An ECF participant change schedule action<br/>It conforms to [ECFParticipantChangeScheduleAttributes](#schema-ecfparticipantchangescheduleattributes) schema. | 


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
| schedule\_identifier | string | true | The new schedule of the participant<br/>Possible values:<br/><br/> - ecf-standard-september<br/> - ecf-standard-january<br/> - ecf-standard-april<br/> - ecf-reduced-september<br/> - ecf-reduced-january<br/> - ecf-reduced-april<br/> - ecf-extended-september<br/> - ecf-extended-january<br/> - ecf-extended-april<br/> - ecf-replacement-september<br/> - ecf-replacement-january<br/> - ecf-replacement-april<br/><br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><br/> - ecf-induction<br/> - ecf-mentor<br/><br/> | 
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
| data | object | true | An ECF participant change schedule action<br/>It conforms to [ECFParticipantChangeSchedule](#schema-ecfparticipantchangeschedule) schema. | 


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


### ECFParticipantCsvRow


The details of an ECF participant

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| id | string | true | The unique identifier of the ECF participant record<br/> | 
| type | string | true | The data type<br/>Possible values:<br/><br/> - participant<br/><br/> | 
| email | string | true | The email registered for this ECF participant<br/> | 
| full\_name | string | true | The full name of the ECF participant<br/> | 
| mentor\_id | string | false | The unique identifier of the ECF participants mentor<br/> | 
| school\_urn | string | true | The Unique Reference Number (URN) of the school the submitted this ECF participant<br/> | 
| participant\_type | string | true | The type of ECF Participant this record refers to either ECT or Mentor<br/>Possible values:<br/><br/> - ect<br/> - mentor<br/><br/> | 
| cohort | string | true | Indicates which call-off contract funds this participant’s training. 2021 indicates a participant that has started, or will start, their training in the 2021/22 academic year.<br/> | 
| status | string | true | The status of the ECF Participant record<br/>Possible values:<br/><br/> - active<br/> - withdrawn<br/><br/> | 
| teacher\_reference\_number | string | false | The Teacher Reference Number (TRN) for this ECF participant<br/> | 
| teacher\_reference\_number\_validated | boolean | false | Indicates whether the Teacher Reference Number (TRN) has been validated<br/> | 
| eligible\_for\_funding | boolean | false | Indicates whether this participant is eligible to receive DfE funded induction<br/> | 
| pupil\_premium\_uplift | boolean | false | Indicates whether this participant qualifies for an uplift payment due to pupil premium<br/> | 
| sparsity\_uplift | boolean | false | Indicates whether this participant qualifies for an uplift payment due to sparsity<br/> | 
| training\_status | string | true | The training status of the ECF Participant<br/>Possible values:<br/><br/> - active<br/> - deferred<br/> - withdrawn<br/><br/> | 
| training\_record\_id | string | true | The unique identifier of the participant training record<br/> | 
| schedule\_identifier | string | true | The schedule of the ECF participant<br/>Possible values:<br/><br/> - ecf-standard-september<br/> - ecf-standard-january<br/> - ecf-standard-april<br/> - ecf-reduced-september<br/> - ecf-reduced-january<br/> - ecf-reduced-april<br/> - ecf-extended-september<br/> - ecf-extended-january<br/> - ecf-extended-april<br/> - ecf-replacement-september<br/> - ecf-replacement-january<br/> - ecf-replacement-april<br/><br/> | 
| updated\_at | string | true | The date the ECF participant was last updated<br/> | 


### ECFParticipantDeclarationPost2024ECTCompletedAttributesRequest


An ECF completed participant declaration

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| participant\_id | string | true | The unique ID of the participant<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><br/> - completed<br/><br/> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><br/> - ecf-induction<br/><br/> | 
| evidence\_held | string | true | The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.<br/>Possible values:<br/><br/> - 75-percent-engagement-met<br/> - 75-percent-engagement-met-reduced-induction<br/> - one-term-induction<br/><br/> | 


### ECFParticipantDeclarationPost2024ECTExtendedAttributesRequest


An ECF extended participant declaration

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| participant\_id | string | true | The unique ID of the participant<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><br/> - extended-1<br/> - extended-2<br/> - extended-3<br/><br/> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><br/> - ecf-induction<br/><br/> | 
| evidence\_held | string | true | The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.<br/>Possible values:<br/><br/> - training-event-attended<br/> - self-study-material-completed<br/> - materials-engaged-with-offline<br/> - other<br/><br/> | 


### ECFParticipantDeclarationPost2024ECTRetainedAttributesRequest


An ECF participant retained declaration

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| participant\_id | string | true | The unique ID of the participant<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><br/> - retained-1<br/> - retained-2<br/> - retained-3<br/> - retained-4<br/><br/> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><br/> - ecf-induction<br/><br/> | 
| evidence\_held | string | true | The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period. For retained-2 declarations, providers will need to confirm if the engagement threshold has been reached and only accept either the ‘75-percent-engagement-met’ or ‘75-percent-engagement-met-reduced-induction’ values.<br/>Possible values:<br/><br/> - training-event-attended<br/> - self-study-material-completed<br/> - materials-engaged-with-offline<br/> - other<br/> - 75-percent-engagement-met<br/> - 75-percent-engagement-met-reduced-induction<br/><br/> | 


### ECFParticipantDeclarationPost2024ECTStartedAttributesRequest


An ECF started participant declaration

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| participant\_id | string | true | The unique ID of the participant<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><br/> - started<br/><br/> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><br/> - ecf-induction<br/><br/> | 
| evidence\_held | string | false | The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.<br/>Possible values:<br/><br/> - training-event-attended<br/> - self-study-material-completed<br/> - materials-engaged-with-offline<br/> - other<br/><br/> | 


### ECFParticipantDeclarationPost2024MentorCompletedAttributesRequest


An ECF completed participant declaration

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| participant\_id | string | true | The unique ID of the participant<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><br/> - completed<br/><br/> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><br/> - ecf-mentor<br/><br/> | 
| evidence\_held | string | true | The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.<br/>Possible values:<br/><br/> - 75-percent-engagement-met<br/> - 75-percent-engagement-met-reduced-induction<br/><br/> | 


### ECFParticipantDeclarationPost2024MentorStartedAttributesRequest


An ECF started participant declaration

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| participant\_id | string | true | The unique ID of the participant<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><br/> - started<br/><br/> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><br/> - ecf-mentor<br/><br/> | 
| evidence\_held | string | false | The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.<br/>Possible values:<br/><br/> - training-event-attended<br/> - self-study-material-completed<br/> - materials-engaged-with-offline<br/> - other<br/><br/> | 


### ECFParticipantDeclarationPre2025CompletedAttributesRequest


An ECF completed participant declaration

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| participant\_id | string | true | The unique ID of the participant<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><br/> - completed<br/><br/> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><br/> - ecf-induction<br/> - ecf-mentor<br/><br/> | 
| evidence\_held | string | true | The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.<br/>Possible values:<br/><br/> - training-event-attended<br/> - self-study-material-completed<br/> - other<br/><br/> | 


### ECFParticipantDeclarationPre2025ExtendedAttributesRequest


An ECF extended participant declaration

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| participant\_id | string | true | The unique ID of the participant<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><br/> - extended-1<br/> - extended-2<br/> - extended-3<br/><br/> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><br/> - ecf-induction<br/> - ecf-mentor<br/><br/> | 
| evidence\_held | string | true | The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.<br/>Possible values:<br/><br/> - training-event-attended<br/> - self-study-material-completed<br/> - other<br/><br/> | 


### ECFParticipantDeclarationPre2025RetainedAttributesRequest


An ECF participant retained declaration

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| participant\_id | string | true | The unique ID of the participant<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><br/> - retained-1<br/> - retained-2<br/> - retained-3<br/> - retained-4<br/><br/> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><br/> - ecf-induction<br/> - ecf-mentor<br/><br/> | 
| evidence\_held | string | true | The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.<br/>Possible values:<br/><br/> - training-event-attended<br/> - self-study-material-completed<br/> - other<br/><br/> | 


### ECFParticipantDeclarationPre2025StartedAttributesRequest


An ECF started participant declaration

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| participant\_id | string | true | The unique ID of the participant<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><br/> - started<br/><br/> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><br/> - ecf-induction<br/> - ecf-mentor<br/><br/> | 


### ECFParticipantDefer


The details of a participant deferral request

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| type | string | true | The data type<br/>Possible values:<br/><br/> - participant-defer<br/><br/> | 
| attributes | object | true | An ECF participant deferral action<br/>It conforms to [ECFParticipantDeferAttributes](#schema-ecfparticipantdeferattributes) schema. | 


### ECFParticipantDeferAttributes


An ECF participant deferral action

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| reason | string | true | The reason for the deferral<br/>Possible values:<br/><br/> - bereavement<br/> - long-term-sickness<br/> - parental-leave<br/> - career-break<br/> - other<br/><br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><br/> - ecf-induction<br/> - ecf-mentor<br/><br/> | 


#### Example


```
{
  "reason": "career-break",
  "course_identifier": "ecf-mentor"
}
```


### ECFParticipantDeferAttributesResponse


The data attributes associated with an ECF participant

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| email | string | true | The email address registered for this ECF participant<br/> | 
| full\_name | string | true | The full name of this ECF participant<br/> | 
| mentor\_id | string | false | The unique identifier of this ECF participants mentor<br/> | 
| school\_urn | string | true | The Unique Reference Number (URN) of the school that submitted this ECF participant<br/> | 
| participant\_type | string | true | The type of ECF participant this record refers to<br/>Possible values:<br/><br/> - ect<br/> - mentor<br/><br/> | 
| cohort | string | true | Indicates which call-off contract funds this participant’s training. 2021 indicates a participant that has started, or will start, their training in the 2021/22 academic year.<br/> | 
| status | string | true | The status of this ECF participant record<br/>Possible values:<br/><br/> - active<br/> - withdrawn<br/><br/> | 
| teacher\_reference\_number | string | false | The Teacher Reference Number (TRN) for this ECF participant<br/> | 
| teacher\_reference\_number\_validated | boolean | false | Indicates whether the Teacher Reference Number (TRN) has been validated<br/> | 
| eligible\_for\_funding | boolean | false | Indicates whether this participant is eligible to receive DfE funded induction<br/> | 
| pupil\_premium\_uplift | boolean | false | Indicates whether this participant qualifies for an uplift payment due to pupil premium<br/> | 
| sparsity\_uplift | boolean | false | Indicates whether this participant qualifies for an uplift payment due to sparsity<br/> | 
| training\_status | string | true | The training status of the ECF participant<br/>Possible values:<br/><br/> - active<br/> - deferred<br/> - withdrawn<br/><br/> | 
| schedule\_identifier | string | true | The schedule of the ECF participant<br/>Possible values:<br/><br/> - ecf-standard-september<br/> - ecf-standard-january<br/> - ecf-standard-april<br/> - ecf-reduced-september<br/> - ecf-reduced-january<br/> - ecf-reduced-april<br/> - ecf-extended-september<br/> - ecf-extended-january<br/> - ecf-extended-april<br/> - ecf-replacement-september<br/> - ecf-replacement-january<br/> - ecf-replacement-april<br/><br/> | 
| updated\_at | string | true | The date the ECF participant was last updated<br/> | 


### ECFParticipantDeferRequest


The deferral request for a participant

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true | The details of a participant deferral request<br/>It conforms to [ECFParticipantDefer](#schema-ecfparticipantdefer) schema. | 


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


### ECFParticipantDeferResponse


An ECF Participant

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true | The details of a participant<br/>It conforms to [ECFParticipantDeferResponseData](#schema-ecfparticipantdeferresponsedata) schema. | 


### ECFParticipantDeferResponseData


The details of a participant

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| id | string | true | The unique identifier of the participant record<br/> | 
| type | string | true | The data type<br/> | 
| attributes | object | true | The data attributes associated with an ECF participant<br/>It conforms to [ECFParticipantDeferAttributesResponse](#schema-ecfparticipantdeferattributesresponse) schema. | 


### ECFParticipantResponse


An ECF Participant

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true | The details of a participant<br/>It conforms to [ECFParticipant](#schema-ecfparticipant) schema. | 


### ECFParticipantResume


An ECF participant resume action

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| type | string | true | The data type<br/>Possible values:<br/><br/> - participant-resume<br/><br/> | 
| attributes | object | true | An ECF participant resume action<br/>It conforms to [ECFParticipantResumeAttributes](#schema-ecfparticipantresumeattributes) schema. | 


### ECFParticipantResumeAttributes


An ECF participant resume action

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><br/> - ecf-induction<br/> - ecf-mentor<br/><br/> | 


#### Example


```
{
  "course_identifier": "ecf-mentor"
}
```


### ECFParticipantResumeAttributesResponse


The data attributes associated with an ECF participant

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| email | string | true | The email address registered for this ECF participant<br/> | 
| full\_name | string | true | The full name of this ECF participant<br/> | 
| mentor\_id | string | false | The unique identifier of this ECF participants mentor<br/> | 
| school\_urn | string | true | The Unique Reference Number (URN) of the school that submitted this ECF participant<br/> | 
| participant\_type | string | true | The type of ECF participant this record refers to<br/>Possible values:<br/><br/> - ect<br/> - mentor<br/><br/> | 
| cohort | string | true | Indicates which call-off contract funds this participant’s training. 2021 indicates a participant that has started, or will start, their training in the 2021/22 academic year.<br/> | 
| status | string | true | The status of this ECF participant record<br/>Possible values:<br/><br/> - active<br/> - withdrawn<br/><br/> | 
| teacher\_reference\_number | string | false | The Teacher Reference Number (TRN) for this ECF participant<br/> | 
| teacher\_reference\_number\_validated | boolean | false | Indicates whether the Teacher Reference Number (TRN) has been validated<br/> | 
| eligible\_for\_funding | boolean | false | Indicates whether this participant is eligible to receive DfE funded induction<br/> | 
| pupil\_premium\_uplift | boolean | false | Indicates whether this participant qualifies for an uplift payment due to pupil premium<br/> | 
| sparsity\_uplift | boolean | false | Indicates whether this participant qualifies for an uplift payment due to sparsity<br/> | 
| training\_status | string | true | The training status of the ECF participant<br/>Possible values:<br/><br/> - active<br/> - deferred<br/> - withdrawn<br/><br/> | 
| schedule\_identifier | string | true | The schedule of the ECF participant<br/>Possible values:<br/><br/> - ecf-standard-september<br/> - ecf-standard-january<br/> - ecf-standard-april<br/> - ecf-reduced-september<br/> - ecf-reduced-january<br/> - ecf-reduced-april<br/> - ecf-extended-september<br/> - ecf-extended-january<br/> - ecf-extended-april<br/> - ecf-replacement-september<br/> - ecf-replacement-january<br/> - ecf-replacement-april<br/><br/> | 
| updated\_at | string | true | The date the ECF participant was last updated<br/> | 


### ECFParticipantResumeRequest


The resume request for a participant

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true | An ECF participant resume action<br/>It conforms to [ECFParticipantResume](#schema-ecfparticipantresume) schema. | 


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


### ECFParticipantResumeResponse


An ECF Participant

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true | The details of a participant<br/>It conforms to [ECFParticipantResumeResponseData](#schema-ecfparticipantresumeresponsedata) schema. | 


### ECFParticipantResumeResponseData


The details of a participant

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| id | string | true | The unique identifier of the participant record<br/> | 
| type | string | true | The data type<br/> | 
| attributes | object | true | The data attributes associated with an ECF participant<br/>It conforms to [ECFParticipantResumeAttributesResponse](#schema-ecfparticipantresumeattributesresponse) schema. | 


### ECFParticipantRetainedDeclaration


An ECF participant retained declaration request body

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| type | object | false | The request data<br/>Possible values:<br/><br/> - participant-declaration<br/><br/> | 
| attributes | object | true | An ECF participant retained declaration<br/>It conforms to [ECFParticipantRetainedDeclarationAttributes](#schema-ecfparticipantretaineddeclarationattributes) schema. | 


### ECFParticipantRetainedDeclarationAttributes


An ECF participant retained declaration

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| participant\_id | string | true | The unique id of the participant<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><br/> - retained-1<br/> - retained-2<br/> - retained-3<br/> - retained-4<br/><br/> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><br/> - ecf-induction<br/> - ecf-mentor<br/><br/> | 
| evidence\_held | string | true | The type of evidence the lead provider holds on their platform to demonstrate the participant has met the retention criteria for the current milestone period.<br/>Possible values:<br/><br/> - training-event-attended<br/> - self-study-material-completed<br/> - other<br/><br/> | 


#### Example


```
{
  "participant_id": "db3a7848-7308-4879-942a-c4a70ced400a",
  "declaration_type": "retained-1",
  "declaration_date": "2021-05-31T02:21:32.000Z",
  "course_identifier": "ecf-induction",
  "evidence_held": "training-event-attended"
}
```


### ECFParticipantStartedDeclaration


A participant started declaration request body

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| type | object | false | The request data<br/>Possible values:<br/><br/> - participant-declaration<br/><br/> | 
| attributes | object | true | An ECF started and completed participant declaration<br/>It conforms to [ECFParticipantStartedDeclarationAttributes](#schema-ecfparticipantstarteddeclarationattributes) schema. | 


### ECFParticipantStartedDeclarationAttributes


An ECF started and completed participant declaration

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| participant\_id | string | true | The unique id of the participant<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><br/> - started<br/> - completed<br/><br/> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><br/> - ecf-induction<br/> - ecf-mentor<br/><br/> | 


#### Example


```
{
  "participant_id": "db3a7848-7308-4879-942a-c4a70ced400a",
  "declaration_type": "started",
  "declaration_date": "2021-05-31T02:21:32.000Z",
  "course_identifier": "ecf-mentor"
}
```


### ECFParticipantWithdraw


An ECF participant withdrawal action

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| type | string | false | The data type<br/>Possible values:<br/><br/> - participant-withdraw<br/><br/> | 
| attributes | object | false | An ECF participant withdrawal action<br/>It conforms to [ECFParticipantWithdrawAttributes](#schema-ecfparticipantwithdrawattributes) schema. | 


### ECFParticipantWithdrawAttributes


An ECF participant withdrawal action

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| reason | string | true | The reason for the withdrawal<br/>Possible values:<br/><br/> - left-teaching-profession<br/> - moved-school<br/> - mentor-no-longer-being-mentor<br/> - switched-to-school-led<br/> - other<br/><br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><br/> - ecf-induction<br/> - ecf-mentor<br/><br/> | 


#### Example


```
{
  "reason": "left-teaching-profession",
  "course_identifier": "ecf-mentor"
}
```


### ECFParticipantWithdrawAttributesResponse


The data attributes associated with an ECF participant

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| email | string | true | The email address registered for this ECF participant<br/> | 
| full\_name | string | true | The full name of this ECF participant<br/> | 
| mentor\_id | string | false | The unique identifier of this ECF participants mentor<br/> | 
| school\_urn | string | true | The Unique Reference Number (URN) of the school that submitted this ECF participant<br/> | 
| participant\_type | string | true | The type of ECF participant this record refers to<br/>Possible values:<br/><br/> - ect<br/> - mentor<br/><br/> | 
| cohort | string | true | Indicates which call-off contract funds this participant’s training. 2021 indicates a participant that has started, or will start, their training in the 2021/22 academic year.<br/> | 
| status | string | true | The status of this ECF participant record<br/>Possible values:<br/><br/> - active<br/> - withdrawn<br/><br/> | 
| teacher\_reference\_number | string | false | The Teacher Reference Number (TRN) for this ECF participant<br/> | 
| teacher\_reference\_number\_validated | boolean | false | Indicates whether the Teacher Reference Number (TRN) has been validated<br/> | 
| eligible\_for\_funding | boolean | false | Indicates whether this participant is eligible to receive DfE funded induction<br/> | 
| pupil\_premium\_uplift | boolean | false | Indicates whether this participant qualifies for an uplift payment due to pupil premium<br/> | 
| sparsity\_uplift | boolean | false | Indicates whether this participant qualifies for an uplift payment due to sparsity<br/> | 
| training\_status | string | true | The training status of the ECF participant<br/>Possible values:<br/><br/> - active<br/> - deferred<br/> - withdrawn<br/><br/> | 
| schedule\_identifier | string | true | The schedule of the ECF participant<br/>Possible values:<br/><br/> - ecf-standard-september<br/> - ecf-standard-january<br/> - ecf-standard-april<br/> - ecf-reduced-september<br/> - ecf-reduced-january<br/> - ecf-reduced-april<br/> - ecf-extended-september<br/> - ecf-extended-january<br/> - ecf-extended-april<br/> - ecf-replacement-september<br/> - ecf-replacement-january<br/> - ecf-replacement-april<br/><br/> | 
| updated\_at | string | true | The date the ECF participant was last updated<br/> | 


### ECFParticipantWithdrawDataResponse


The details of a participant

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| id | string | true | The unique identifier of the participant record<br/> | 
| type | string | true | The data type<br/> | 
| attributes | object | true | The data attributes associated with an ECF participant<br/>It conforms to [ECFParticipantWithdrawAttributesResponse](#schema-ecfparticipantwithdrawattributesresponse) schema. | 


### ECFParticipantWithdrawRequest


The withdrawal request for a participant

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true | An ECF participant withdrawal action<br/>It conforms to [ECFParticipantWithdraw](#schema-ecfparticipantwithdraw) schema. | 


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


### ECFParticipantWithdrawResponse


An ECF Participant

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true | The details of a participant<br/>It conforms to [ECFParticipantWithdrawDataResponse](#schema-ecfparticipantwithdrawdataresponse) schema. | 


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
| error | array | false | It conforms to [Error](#schema-error) schema. | 


### ListFilter


Filter a list of records to return more specific results

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| updated\_since | string | false | Return only records that have been updated since this date and time (ISO 8601 date format)<br/> | 
| created\_since | string | false | Return only records that have been created since this date and time (ISO 8601 date format)<br/> | 


### ListFilterDeclarations


Filter a list of declarations records to return more specific results

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| updated\_since | string | false | Return only records that have been updated since this date and time (ISO 8601 date format)<br/> | 
| participant\_id | string | false | The unique id of the participant<br/> | 


### MultipleECFParticipantsCsvResponse


A list of ECF participants in the Comma Separated Value (CSV) format

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | array | true | It conforms to [ECFParticipantCsvRow](#schema-ecfparticipantcsvrow) schema. | 


### MultipleECFParticipantsResponse


A list of ECF participants

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | array | true | It conforms to [ECFParticipant](#schema-ecfparticipant) schema. | 


### MultipleParticipantDeclarationsCsvResponse


A list of participant declarations in the Comma Separated Value (CSV) format

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | array | true | It conforms to [ParticipantDeclarationCsvRow](#schema-participantdeclarationcsvrow) schema. | 


### MultipleParticipantDeclarationsResponse


A list of participant declarations

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | array | true | It conforms to [ParticipantDeclarationResponse](#schema-participantdeclarationresponse) schema. | 


### NotFoundResponse


The requested resource was not found

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| error | string | false |  | 


### Pagination


This schema used to paginate through a collection.

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| page | integer | false | The page number to paginate to in the collection. If no value is specified it defaults to the first page.<br/> | 
| per\_page | integer | false | The number items to display on a page. Defaults to 100. Maximum is 3000, if the value is greater that the maximum allowed it will fallback to 3000.<br/> | 


### ParticipantDeclaration


A participant declaration

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true | It conforms to [] schema. | 


#### Example


```
{
  "data": {
    "type": "participant-declaration",
    "attributes": {
      "participant_id": "db3a7848-7308-4879-942a-c4a70ced400a",
      "declaration_type": "started",
      "declaration_date": "2021-05-31T02:21:32.000Z",
      "course_identifier": "ecf-mentor"
    }
  }
}
```


### ParticipantDeclarationAttributes


The data attributes associated with a participant declaration response

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| participant\_id | string | true | The unique id of the participant<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><br/> - started<br/> - retained-1<br/> - retained-2<br/> - retained-3<br/> - retained-4<br/> - completed<br/> - extended-1<br/> - extended-2<br/> - extended-3<br/><br/> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><br/> - ecf-induction<br/> - ecf-mentor<br/><br/> | 
| eligible\_for\_payment | boolean | true | [Deprecated - use state instead] Indicates whether this declaration would be eligible for funding from the DfE<br/> | 
| voided | boolean | true | [Deprecated - use state instead] Indicates whether this declaration has been voided<br/> | 
| state | string | true | Indicates the state of this payment declaration<br/>Possible values:<br/><br/> - submitted<br/> - eligible<br/> - payable<br/> - paid<br/> - voided<br/> - ineligible<br/> - awaiting-clawback<br/> - clawed-back<br/><br/> | 
| updated\_at | string | true | The date the declaration was last updated<br/> | 
| has\_passed | boolean | false | Whether the participant has failed or passed<br/> | 


### ParticipantDeclarationCsvRow


The details of a participant declaration

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| id | string | true | The unique identifier of the participant declaration record<br/> | 
| participant\_id | string | true | The unique identifier of the participant record the declaration refers to<br/> | 
| declaration\_type | string | true | The event declaration type<br/>Possible values:<br/><br/> - started<br/> - retained-1<br/> - retained-2<br/> - retained-3<br/> - retained-4<br/> - completed<br/> - extended-1<br/> - extended-2<br/> - extended-3<br/><br/> | 
| declaration\_date | string | true | The event declaration date<br/> | 
| course\_identifier | string | true | The type of course the participant is enrolled in<br/>Possible values:<br/><br/> - ecf-induction<br/> - ecf-mentor<br/><br/> | 
| eligible\_for\_payment | boolean | true | [Deprecated - use state instead] Indicates whether this declaration would be eligible for funding from the DfE<br/> | 
| voided | boolean | true | [Deprecated - use state instead] Indicates whether this declaration has been voided<br/> | 
| state | string | false | Indicates the state of this payment declaration<br/> | 
| updated\_at | string | true | The date the declaration was last updated<br/> | 


### ParticipantDeclarationPost2024ECTDataRequest


A participant declaration data request for ECT participants from cohort 2025 onwards

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| type | string | false | Possible values:<br/><br/> - participant-declaration<br/><br/> | 
| attributes | object | false | This conforms to any of the following schemas:<br/><br/> -  [ECFParticipantDeclarationPost2024ECTStartedAttributesRequest](#schema-ecfparticipantdeclarationpost2024ectstartedattributesrequest) <br/> -  [ECFParticipantDeclarationPost2024ECTRetainedAttributesRequest](#schema-ecfparticipantdeclarationpost2024ectretainedattributesrequest) <br/> -  [ECFParticipantDeclarationPost2024ECTCompletedAttributesRequest](#schema-ecfparticipantdeclarationpost2024ectcompletedattributesrequest) <br/> -  [ECFParticipantDeclarationPost2024ECTExtendedAttributesRequest](#schema-ecfparticipantdeclarationpost2024ectextendedattributesrequest) <br/><br/> | 


### ParticipantDeclarationPost2024MentorDataRequest


A participant declaration data request for mentor participants from cohort 2025 onwards

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| type | string | false | Possible values:<br/><br/> - participant-declaration<br/><br/> | 
| attributes | object | false | This conforms to any of the following schemas:<br/><br/> -  [ECFParticipantDeclarationPost2024MentorStartedAttributesRequest](#schema-ecfparticipantdeclarationpost2024mentorstartedattributesrequest) <br/> -  [ECFParticipantDeclarationPost2024MentorCompletedAttributesRequest](#schema-ecfparticipantdeclarationpost2024mentorcompletedattributesrequest) <br/><br/> | 


### ParticipantDeclarationPre2025DataRequest


A participant declaration data request for participants in cohort 2024 and previous years

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| type | string | false | Possible values:<br/><br/> - participant-declaration<br/><br/> | 
| attributes | object | false | This conforms to any of the following schemas:<br/><br/> -  [ECFParticipantDeclarationPre2025StartedAttributesRequest](#schema-ecfparticipantdeclarationpre2025startedattributesrequest) <br/> -  [ECFParticipantDeclarationPre2025RetainedAttributesRequest](#schema-ecfparticipantdeclarationpre2025retainedattributesrequest) <br/> -  [ECFParticipantDeclarationPre2025CompletedAttributesRequest](#schema-ecfparticipantdeclarationpre2025completedattributesrequest) <br/> -  [ECFParticipantDeclarationPre2025ExtendedAttributesRequest](#schema-ecfparticipantdeclarationpre2025extendedattributesrequest) <br/><br/> | 


### ParticipantDeclarationRequest


An participant declaration request

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true | This conforms to any of the following schemas:<br/><br/> -  [ParticipantDeclarationPre2025DataRequest](#schema-participantdeclarationpre2025datarequest) <br/> -  [ParticipantDeclarationPost2024ECTDataRequest](#schema-participantdeclarationpost2024ectdatarequest) <br/> -  [ParticipantDeclarationPost2024MentorDataRequest](#schema-participantdeclarationpost2024mentordatarequest) <br/><br/> | 


### ParticipantDeclarationResponse


A participant declaration response

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| id | string | true | The unique identifier of the participant declaration record<br/> | 
| type | string | true | The data type<br/> | 
| attributes | object | true | The data attributes associated with a participant declaration response<br/>It conforms to [ParticipantDeclarationAttributes](#schema-participantdeclarationattributes) schema. | 


### ParticipantListFilter


Filter a list of records to return more specific results

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| updated\_since | string | false | Return only records that have been updated since this date and time (ISO 8601 date format)<br/> | 
| cohort | string | false | Return only records for the given cohort<br/> | 


### SingleParticipantDeclarationResponse


A confirmation that the participant declaration has been recorded successfully

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| data | object | true | A participant declaration response<br/>It conforms to [ParticipantDeclarationResponse](#schema-participantdeclarationresponse) schema. | 


### UnauthorisedResponse


Authorization information is missing or invalid

| Name | Type | Required | Description |
| ---- | ---- | ---- | ---- |
| error | string | false |  | 

