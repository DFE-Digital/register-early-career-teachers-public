---
title: Lead providers
---

# API Change Management Guidelines

## Breaking and Non-Breaking Changes Explained

### The Difference Between Breaking and Non-Breaking Changes and Impact on Providers

When we decide to make a change to an API, our technical team must consider how it might affect lead providers and their integrations. This is because if a proposed change breaks how a provider’s app talks to the API, their integrations could stop working correctly.

This means they may not be able to:

- Process the data provided by the API  
- Submit requests via the API  

## Breaking Changes

A breaking change disrupts the existing functionality or behaviour of the API, causing lead provider integrations to fail or behave unexpectedly.

Breaking changes include:

- Removing an existing endpoint  
- Changing the data structure, field values or format in which we serve data to lead providers  
- Introducing new validation rules or required fields  

### Example: Changing the Response Format of an Existing Endpoint

#### From:
```json
{
  "participant_id": "21412-12121",
  "name": "Bukayo Saka",
  "status": "active"
}
```

#### To:
```json
{
  "participant_id": "21412-12121",
  "name": "Bukayo Saka",
  "is_active": true
}
```
This is a breaking change because it changes a field name and data type. Lead providers rely on expecting a specific field name or value. Both changes could break existing integrations for providers who expect a `status` field with a "string" rather than `is_active` and `true` or `false`.

## Non-Breaking Changes

A non-breaking change does not break or disrupt existing functionality or behaviour of the API. Providers can continue to consume the data and integrate and apply the change when they are ready.

Non-breaking changes include:

- New endpoints (for example, ECF transfers)  
- Adding optional fields to the request body  
- Adding new optional filters to an endpoint (e.g., a non-required ability to filter by cohort on the get declarations endpoint)  

### Example: Introducing `evidence_held` as an Optional Field in the Request Body to Start Declarations for Cohort 2025

Currently, `evidence_held` is not a required field for ECF start declarations:

#### As-Is Start Declaration Request Body

| Name              | Required (Yes/No) | Type   | Description/Possible Values |
|------------------|----------------|--------|-----------------------------|
| `participant_id` | Yes            | String | Unique ID of the participant |
| `declaration_type` | Yes            | String | The declaration type <br> Possible values: `started` |
| `declaration_date` | Yes            | String | The event declaration date |
| `course_identifier` | Yes            | String | The type of course the participant is enrolled on <br> Possible values: `ecf-induction`, `ecf-mentor` |

For cohort 2025 and onwards, evidence types will be an optional field that providers can supply when submitting start declarations.

#### To-Be: Introducing a New Optional Field to the Request Body

| Name              | Required (Yes/No) | Type   | Description/Possible Values |
|------------------|----------------|--------|-----------------------------|
| `participant_id` | Yes            | String | Unique ID of the participant |
| `declaration_type` | Yes            | String | The declaration type <br> Possible values: `started` |
| `declaration_date` | Yes            | String | The event declaration date |
| `course_identifier` | Yes            | String | The type of course the participant is enrolled on <br> Possible values: `ecf-induction`, `ecf-mentor` |
| `evidence_held`  | No             | String | The type of evidence the lead provider holds <br> Possible values: `training-event-attended`, `self-study-material-completed`, `other`, `materials-engaged-with-offline` |

This is a non-breaking change because providers are still able to submit start declarations without supplying an evidence types. If the field was mandatory, providers would encounter an error message when submitting requests. 

In this instance, providers can update their integrations to submit start declarations and evidence types whenever they are ready and continue to submit start declarations without an evidence type for the time being.

## Release management and provider engagement

Release management is crucial to ensure that Lead Providers have a positive experience when adopting the changes for our API. It's the DfE's responsibility to ensure that providers are **well-informed**, **prepared** and **supported** throughout the release. This ensures that the delivery of the ECF training is not impacted. For any changes breaking or non-breaking LPDOB:

- Engage with providers as early as possible, ensuring they have visibility of the upcoming changes and are consulted.
- Share detailed specifications, release note and updated guidance are shared as soon as they are available. This helps providers assess the impact on their systems and plan necessary updates.  
- Attend check-ins and engaging with technical teams for lead providers to walk through the changes, answer questions, and gather feedback on any implementation concerns.  
- Release the updated API into the sandbox environment, allowing providers to conduct testing and validate integrations before changes go live.
- For breaking changes, retrieve feedback from providers on their timelines to integrate and test. 

We appreciate that these changes can have huge ramifications on their integrations and thus their ability to deliver of the ECF policy.
 

## Versioning and Managing Changes

Best practice suggests requiring a new API version for breaking changes, allowing users to smoothly migrate without disrupting existing processes.
Due to the urgency of some changes, this practice hasn't always been followed, but we're committed to adhering to best practices moving forward.
