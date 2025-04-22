---
title: Lead provider API
---

Learn about lifecycle and interactions associated with participant declarations within our system.

A declaration represents a formal statement submitted by a Lead Provider, using the Early Career Framework API, regarding a participant's status or outcome linked to a specific course the participant is enrolled in.

Understanding this journey is crucial for comprehending data flow, participant tracking, and the methodology behind calculating associated fees and payments. This section covers how Lead Providers interact with declarations and how internal users access this information.

## Contents

[Declarations in a nutshell](#declarations-in-a-nutshell)

[Lead providers submitting a declaration](#lead-providers-submitting-a-declaration)

[Lead providers reviewing submitted declarations](#lead-providers-reviewing-submitted-declarations)

[Declaration States](#declaration-states)

[Lead providers checking whether a declaration has been successfully submitted and processed](#lead-providers-checking-whether-a-declaration-has-been-successfully-submitted-and-processed)

[Internal User Access](#internal-user-access)

## Declarations in a nutshell

Declarations are submitted where there is evidence of a participant's engagement in training for a given milestone period. This is submitted by lead providers via the API and triggers payments to lead providers.

Declarations serve as the critical "bridge" between proving training engagement and triggering the financial outputs (payments) from the DfE.

Declarations are treated in "good faith" meaning that providing the declaration is valid and the participant is eligible for funding then they will be paid.

## Lead providers submitting a declaration

A lead provider can submit a declaration using the POST `api/v[1,2,3]/participant-declarations` endpoint, providers are required to supply the request body, which includes the:

- participant id
- declaration type
- declaration date
- course identifier
- evidence held

Example:

<pre><code>{
  "data": {
    "type": "participant-declaration",
    "attributes": {
      "participant_id": "eb61b470-e1d3-4c38-a5bf-b94c998f47cb",
      "declaration_type": "started",
      "declaration_date": "2023-12-01T02:21:32.000Z",
      "course_identifier": "ecf-induction",
      "evidence_held": "training-event-attended"
    }
  }
}</code></pre>

## Lead providers reviewing submitted declarations

A lead provider can view all declarations using the GET `api/v[1,2,3]/participant-declarations` endpoint.

Example:

<pre><code>{
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
}</code></pre>

Also lead providers have real-time status updates of a specific declaration via the endpoint GET `api/v[1,2,3]/participant-declarations/{id}`.

## Declaration States

Declarations progress through various states, reflecting their journey from submission through validation, payment processing, and potential reconciliation. The state determines eligibility for payment and informs required actions. Possible states include:

* **`submitted`**: The declaration has been received by the system but has not yet undergone validation.
* **`eligible`**: The declaration has passed initial validation checks and is potentially eligible for payment.
* **`payable`**: The declaration is validated, eligible, and queued for inclusion in the next payment run.
* **`paid`**: Payment associated with this declaration has been processed.
* **`voided`**: The declaration has been cancelled or invalidated, often due to an error or subsequent correction. It is excluded from payment calculations.
* **`ineligible`**: The declaration is duplicate declaration. Payment will not be processed.
* **`awaiting_clawback`**: A determination has been made that a previously paid declaration needs to be clawed back, and the clawback process is pending or in progress.
* **`clawed_back`**: Payment was initially made for this declaration, but has subsequently been recouped (e.g., due to evidence issues, participant withdrawal after payment).

The `state` field returned when retrieving declarations, via the API, indicates its position in this lifecycle.

## Lead providers checking whether a declaration has been successfully submitted and processed

A valid declaration will return a 200 response whereas an invalid declaration request will return an error message.

Many validations are in place to guarantee a declaration is correctly created:

### 1. Automatic Checks Before Validation
- The system verifies whether the selected course is still supported.
- It tracks declaration attempts to prevent unnecessary or duplicate submissions.

### 2. Required Information
- **Participant Id** – Must be provided; otherwise, an error message is shown.
- **Declaration Type** – Must be provided; otherwise, an error message is shown.
- **Declaration Date** – Must be provided; otherwise, an error message is shown.
- **Course Identifier** – Must be provided; otherwise, an error message is shown.
- **Evidence Held** – Must be provided for some declaration types; otherwise, an error message is shown.

### 3. Participant Requirements
- The participant must have a valid identity in the system.
- The participant must not have withdrawn from the program.

### 4. Date Validations
- The **declaration date** must be a valid date.
- The **declaration date** cannot be in the future.
- The **declaration date** must be within each declaration type milestone start dates.

### 5. Course & Provider Validations
- The **course identifier** must be valid for the given participant.
- The **lead provider** must be correctly linked to the participant.

### 6. Additional Compliance Checks
- The system checks if the required **statement** is available.
- A **valid milestone** must exist for the declaration.
- The system checks for duplicated declarations.
- From academic year 2025-26, if the participant is a **mentor**, they can only declare a `started` or `completed` status.
- The provided **evidence** must meet the necessary requirements.

These validations help ensure accurate and compliant record declarations while preventing errors in the process.

## Internal User Access

Internal users access declaration details through dedicated applications tailored to their roles.

### Finance User Access (Finance App)

* **Action:** Finance users can view declaration details via the Finance application.
* **Purpose:** To review declarations relevant to payment runs, reconcile payments, investigate discrepancies, and audit financial statements.
* **View:** The Finance App typically displays declarations focusing on financial implications, showing fields like:
    * `declaration_id`
    * `participant_id`
    * `declaration_type`
    * `declaration_date`
    * `state` (especially filtering for `ELIGIBLE`, `PAID`, `AWAITING_CLAWBACK`, `CLAWED_BACK`)
    * Associated payment amounts and dates
    * Links to related financial statements

### Admin User Access (Admin App)

* **Action:** Admin users can view declaration details via the Admin application.
* **Purpose:** To provide comprehensive oversight, troubleshoot issues, support Lead Providers, and potentially perform administrative actions on declarations.
* **View:** The Admin App typically offers a more detailed view, including:
    * All fields visible to Finance users.
    * Detailed state history and transition timestamps.
    * Submission details (timestamp, submitting provider).
    * Links to participant profiles and course details.
    * Potentially, administrative functions like manually voiding a declaration (with appropriate permissions and audit trails).
