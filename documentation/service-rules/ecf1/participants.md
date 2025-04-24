---
title: Lead provider API
---

# ECF participants endpoint documentation

This documentation provides a comprehensive guide to the ECF API (Early Career Framework) participants endpoint. It serves as a reference for both technical and product teams, ensuring everyone understands how participant data is structured, accessed, and managed within the system.

The ECF participants endpoint allows authorized users to retrieve information about Early Career Teachers (ECTs) and Mentors who are registered in the ECF programme. This documentation explains the participant journey from registration to API visibility, detailing the conditions, attributes, and interactions involved in the process.

## Contents

[Participant types](#participant-types)

[Participant interactions](#participant-interactions)

[API access conditions](#api-access-conditions)

[Participant attributes](#participant-attributes)

[API endpoints](#api-endpoints)

[User access](#user-access)

[Error handling](#error-handling)

[Participant journeys](#participant-journeys)

[Glossary](#glossary)

## Participant types

The ECF service supports two types of participants:

### Early career teachers (ECTs)

ECTs are teachers in the first two years of their career who receive structured mentoring and support through the ECF programme. They are the primary beneficiaries of the programme and have specific attributes and statuses that track their progress.

### Mentors

Mentors are experienced teachers who provide guidance and support to ECTs. They are also registered in the system and have their own set of attributes and statuses.

Both participant types follow similar registration processes but may have different attributes and relationships within the system.

## Participant interactions

### School induction tutor registration

The participant journey begins when a school induction tutor registers an ECT or Mentor in the system. The registration process involves:

1. The induction tutor enters the participant's details, including:
   - Full name
   - Email address
   - Teacher Reference Number (TRN)
   - School details

2. The system validates the information, particularly the TRN, to ensure it corresponds to a registered teacher.

3. Upon successful validation, the participant is created in the system with an initial status of "active".

### Partnership requirements

For participants to be visible via the API, a partnership must exist between:

- The school where the participant is registered
- A lead provider who delivers the training

This partnership establishes the relationship necessary for data sharing and training delivery.

### Lead provider relationship

The lead provider must have one of the following relationships with the school:

- Be the default partnership for the school
- Have an established relationship with that school

Without this relationship, participants will not be visible through the API.

## API access conditions

To successfully retrieve participants via the API, all three of the following conditions must be met:

1. **Partnership Formation**: A partnership must be formed between the lead provider and the school.
2. **Participant Registration**: The participant must be registered in the system by a school induction tutor.
3. **Lead Provider Relationship**: The lead provider must be either:
   - The default partnership for the school, or
   - Have an established and not challenged relationship with the school

If any of these conditions are not met or in the case a partnership is challenged, the participant will not be visible through the API, and appropriate error responses will be returned.

## Participant attributes

When a participant is registered in the system, they are assigned various attributes that define their status, relationship with schools and providers, and other important information:

### Schedule

The `schedule_identifier` attribute defines the training schedule for the participant. Examples include:

- `ecf-standard-january`: Standard ECF schedule starting in January
- `ecf-standard-september`: Standard ECF schedule starting in September

The schedule determines the timeline for training activities and assessments.

### Training status

The `training_status` attribute indicates the current training state of the participant. Possible values include:

- `active`: Participant is actively engaged in training
- `deferred`: Participant has temporarily paused their training
- `withdrawn`: Participant has permanently left the training programme

This status is updated when actions like defer, withdraw, or resume are performed on a participant.

### Status

The `participant_status` attribute indicates the administrative status of the participant. Possible values include:

- `active`: Participant is currently active or has completed a training programme
- `leaving`: Participant is leaving a training programme
- `left`: Participant has left a training programme
- `joining`: Participant is joining a training programme
- `withdrawn`: Participant has withdrawn from a training programme

This status may differ from the training status and also reflects the administrative state rather than the training state.

### URN (unique reference number)

The `school_urn` attribute is the unique identifier for the school where the participant is registered. This is a 6-digit number assigned to educational establishments in England and Wales.

### Delivery partner id

The `delivery_partner_id` attribute identifies the delivery partner responsible for providing training to the participant. This is a UUID that links to a delivery partner record.

### TRN (teacher reference number)

The `teacher_reference_number` attribute is a unique identifier assigned to qualified teachers. The system validates this number to ensure it corresponds to a registered teacher.

The `teacher_reference_number_validated` boolean attribute indicates whether the TRN has been successfully found and validated in the database of qualified teachers (DQT).

### Participant id changes

The `participant_id_changes` array tracks any changes to a participant's ID. Each entry includes:

- `from_participant_id`: The previous participant ID
- `to_participant_id`: The new participant ID
- `changed_at`: Timestamp when the change occurred

This tracking ensures continuity when participant records are merged or updated.

### Timestamps

Two important timestamps are tracked for each participant:

- **updated_at**: This timestamp is updated whenever any attribute or linked record of the participant is modified. Examples of actions that trigger an update:
  - Changing training status (defer, withdraw, resume)
  - Updating personal information
  - Changing the assigned mentor
  - Modifying the training schedule
  - Moving to another school
  - Modifying the default partnership

- **created_at**: This timestamp is set when the participant is first registered in the system and remains unchanged.

#### Example of timestamp updates

When a school induction tutor registers an ECT:
<pre><code>{
"created_at": "2023-09-01T10:15:22.000Z",
"updated_at": "2023-09-01T10:15:22.000Z"
}</code></pre>

When the ECT's training status is changed to deferred:
<pre><code>{
"created_at": "2023-09-01T10:15:22.000Z",
"updated_at": "2023-10-15T14:30:45.000Z"
}</code></pre>

## API endpoints

### `GET /api/v3/participants/ecf`

This endpoint allows you to retrieve multiple ECF participants. It replaces the legacy `/api/v{1,2}/participants` endpoint and includes updated specifications.

#### Request parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| filter | object | No | Refine ECF participants to return using the ECFParticipantFilter schema |
| page | object | No | Pagination options to navigate through the list of ECF participants |
| sort | array | No | Sort ECF participants being returned |

##### Filter parameters (ECFParticipantFilter)

| Name | Type | Required | Description |
|------|------|----------|-------------|
| updated_since | string | No | Return only records that have been updated since this date and time (ISO 8601 date format) |
| cohort | string | No | Return only records for the given cohort |
| training_status | string | No | Return only records that have this training status |
| from_participant_id | string | No | Return only records that have this from Participant ID |

##### Pagination parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| page | integer | No | Page number to return |
| per_page | integer | No | Number of records per page |

##### Sort parameters

| Value | Description |
|-------|-------------|
| updated_at | Sort by updated_at timestamp in ascending order |
| -updated_at | Sort by updated_at timestamp in descending order |

#### Example request

<pre><code>
GET /api/v3/participants/ecf?filter[cohort]=2022&filter[training_status]=active&page[page]=1&page[per_page]=5&sort=-updated_at
</code></pre>

#### Response (200 OK)

The response returns a MultipleECFParticipantsResponse schema:

<pre><code>{
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
}</code></pre>

### `GET /api/v3/participants/ecf/{id}`

This endpoint allows you to retrieve a single ECF participant by their ID.

#### Path parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | string | Yes | The ID of the ECF participant |

#### Example request

<pre><code>
GET /api/v3/participants/ecf/ac3d1243-7308-4879-942a-c4a70ced400a
</code></pre>

#### Response (200 OK)

The response returns a SingleECFParticipantResponse schema with detailed information about the requested participant.

## User access

Different users can access participant information based on their role:

### Provider access

Providers can retrieve participant information through the API, allowing them to:
- View all participants associated with their partnerships
- Access detailed information about specific participants
- Track changes in participant status

### Finance user access

Finance users can view participant details through the finance application, focusing on:
- Funding eligibility
- Pupil premium and sparsity uplifts
- Mentor funding end dates
- Cohort information relevant to payments

### Admin user access

Admin users have comprehensive access through the admin application to:
- View and manage all participant details
- Track status changes
- Monitor partnerships
- Oversee the entire participant journey

## Error handling

### Authentication errors (401 unauthorized)

If the request does not include valid authentication credentials, the API will return a 401 Unauthorized response:

<pre><code>{
  "error": "HTTP Token: Access denied"
}</code></pre>

### Bad request errors (400 bad request)

If the request contains invalid parameters, the API will return a 400 Bad Request response with details about the errors:

<pre><code>{
  "errors": [
    {
      "title": "Bad request",
      "detail": "correct json data structure required. See API docs for reference"
    }
  ]
}</code></pre>

### Not found errors (404 not found)

If the requested participant ID does not exist, the API will return a 404 Not Found response.

## Participant journey

### ECT/Mentor participant registration and API visibility journey

1. **Registration**: A school induction tutor registers an Early Career Teacher (ECT) or a Mentor in the system, providing their details including name, email, TRN, and school information.

2. **Partnership Check**: The system checks if a partnership exists between the school and a lead provider.
   - If no partnership exists, the participant will not be visible via the API.
   - If a partnership exists, the process continues.

3. **Lead Provider Relationship Check**: The system verifies if the lead provider has a relationship with the school.
   - If no relationship exists, the participant will not be visible via the API.
   - If a relationship exists, the participant becomes visible via the API.

4. **Mentor-ECT Assignment**: Once registered, the Mentor can be assigned to one or more ECTs.
   - When assigned, the Mentor's ID is added to the ECT's record.
   - This assignment triggers an update to the ECT's "updated_at" timestamp.

5. **Data Access**: Once visible via the API, the participant's data can be:
   - Retrieved by providers through the API
   - Accessed by finance users through the finance application
   - Accessed by admin users through the admin application

6. **Status Changes**: Throughout their journey, a participant may undergo various status changes:
   - **Defer**: Training status changes to "Deferred" when the participant temporarily pauses their training
   - **Withdraw**: Training status changes to "Withdrawn" when the participant permanently leaves the programme
   - **Resume**: Training status changes to "Active" when a previously deferred participant returns to training

7. **Timestamp Updates**: Each time a status change occurs, the "updated_at" timestamp is modified to reflect the most recent change, while the "created_at" timestamp remains unchanged from the initial registration.

### API data retrieval process

1. **API Request Initiation**: A provider system initiates an API request to either:
   - Retrieve multiple participants using `GET /api/v{1,2,3}/participants/ecf`
   - Retrieve a specific participant using `GET /api/v{1,2,3}/participants/ecf/{id}`

2. **Filtering (for multiple participants)**: When retrieving multiple participants, the provider can apply filters:
   - Filter by cohort (e.g., 2021, 2022)
   - Filter by training status (e.g., active, deferred or withdrawn)
   - Filter by update date (participants updated since a specific date)
   - Filter by participant ID

3. **Pagination**: For multiple participant requests, pagination can be applied:
   - Specify page number and records per page
   - If not specified, default pagination settings are applied

4. **Sorting**: Results can be sorted:
   - Sort by updated_at timestamp (ascending or descending)
   - If not specified, default sorting is applied

5. **Response Processing**: The provider system processes the API response:
   - For multiple participants: processes the list of participant records
   - For single participant: processes the detailed participant data

6. **Error Handling**: If errors occur during the API request, they are handled appropriately:
   - Authentication errors (401 Unauthorized) if credentials are invalid
   - Bad Request errors (400 Bad Request) if parameters are invalid
   - Not Found errors (404 Not Found) if the requested participant doesn't exist

### Participant status lifecycle

1. **Initial Registration**: When a participant is first registered, they are assigned an initial status of "Active".

2. **Status Change Events**: Throughout their journey, a participant may experience various status change events:
   - **Deferral Request**: When a participant needs to temporarily pause their training, a deferral request is submitted using `PUT /api/v{1,2,3}/participants/ecf/{id}/defer`
   - **Withdrawal Request**: When a participant permanently leaves the programme, a withdrawal request is submitted using `PUT /api/v{1,2,3}/participants/ecf/{id}/withdraw`
   - **Resume Request**: When a previously deferred participant returns to training, a resume request is submitted using `PUT /api/v{1,2,3}/participants/ecf/{id}/resume`
   - **Schedule Change**: When a participant's training schedule needs to be modified, a schedule change request is submitted using `PUT /api/v{1,2,3}/participants/ecf/{id}/change-schedule`

3. **Status Updates**: Following these requests, the participant's status is updated accordingly:
   - Deferral Request → Status updated to "Deferred"
   - Withdrawal Request → Status updated to "Withdrawn"
   - Resume Request → Status updated to "Active"
   - Schedule Change → Schedule is updated while status remains unchanged

4. **Timestamp Updates**: Each status change triggers an update to the "updated_at" timestamp, recording when the change occurred.

5. **System Updates**: After a status change, the participant record is updated in the system, and the updated data becomes available via the API.

6. **Visibility**: The updated participant information is visible to:
   - Providers (via the API)
   - Finance users (via the finance application)
   - Admin users (via the admin application)

## Glossary

- **ECF**: Early Career Framework - A two-year programme of professional development for teachers at the start of their career.
- **ECT**: Early Career Teacher - A teacher in their first two years of teaching.
- **TRN**: Teacher Reference Number - A unique identifier assigned to qualified teachers.
- **URN**: Unique Reference Number - A unique identifier for educational establishments in England and Wales.
- **Induction Tutor**: A school staff member responsible for registering and supporting ECTs.
- **Lead Provider**: An organization contracted to deliver ECF training.
- **Delivery Partner**: An organization working with a lead provider to deliver training.
- **Partnership**: A formal relationship between a school and a lead provider.
- **Cohort**: A group of participants who start their ECF journey at the same time.
- **API**: Application Programming Interface - A set of rules that allows different software applications to communicate with each other.
