---
title: Lead provider API
---

Learn about how our payment engine works once it receives declarations from lead providers using the Early Career Framework API.

These are the steps

1. Provider submits a declaration.
2. The system validates data.
3. If invalid, errors are flagged up with corrective action suggestions.
4. If valid, the declaration is created and linked to an output fee calculation.
5. Service fees and banding are determined and applied.
6. Final payments are calculated and displayed for contract managers.

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

## Lead providers checking which statement a declaration has been linked to

Lead providers can check for updates on the statement a declaration has been linked to and its status, via the endpoint GET `/api/v[1,2,3]/statements/{id}`, using the `statement_id` from the declaration response above as `{id}`.

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
- If the participant is a **mentor**, they can only declare a `started` or `completed` status.
- The provided **evidence** must meet the necessary requirements.

These validations help ensure accurate and compliant record declarations while preventing errors in the process.

### Possible validation error messages:

- `Your update cannot be made as the '#/participant_id' is not recognised. Check participant details and try again.`
- `This participant withdrew from this course on %{withdrawal_date}. Enter a '#/declaration_date' that's on or before the withdrawal date.`
- `You cannot submit or void declarations for the %{cohort} cohort. The funding contract for this cohort has ended. Get in touch if you need to discuss this with us`
- `The entered '#/course_identifier' is not recognised for the given participant. Check details and try again.`
- `NPQ Courses are no longer supported`
- `Enter a '#/declaration_date'.`
- `Enter a valid RCF3339 '#/declaration_date'.`
- `Enter a '#/evidence_held' value for this participant.`
- `Enter an available '#/evidence_held' type for this participant's event and course.`
- `A declaration has already been submitted that will be, or has been, paid for this event`
- `The property '#/declaration_type' does not exist for this schedule.`
- `Enter a '#/declaration_date' that's on or after the milestone start.`
- `Enter a '#/declaration_date' that's before the milestone end date.`
- `The '#/declaration_date' value cannot be a future date. Check the date and try again.`
- `You cannot send retained or extended declarations for participants who began their mentor training after June 2025. Resubmit this declaration with either a started or completed declaration.`

## Working with participant bands

Given the data:

- **Bands:**
  - **Band A**: 0 to 2000 participants
  - **Band B**: 2000 to 4000 participants
  - **Band C**: 4000 participants and up to a maximum of 115% of the contract's target volume
- **Previous participants**: 2100
- **Current participants**: 2000
- **Goal**: Distribute these 2000 participants into the bands.

### Breakdown

#### **Previous Distribution:**
- The **first 2000** participants recruited in a cohort were in **Band A**.
- The **next 100** participants (out of 2100) moved into **Band B**.

#### **Current Distribution (2000 participants):**
- Since all 2000 participants fit within **Band A’s range (0–2000)**,
  **Band A now has 0 participants**.
- The remaining participants (from 2000 onwards) move into **Band B and Band C**:
  - **Band B** starts at 2000. Since we need to place 2000 participants:
    - 1900 fit into **Band B** (since the previous 100 were already in Band B, we adjust).
    - The remaining 100 go into **Band C**.

### **Final Result:**
| Band   | Participants |
|--------|-------------|
| Band A | 0           |
| Band B | 1900        |
| Band C | 100         |

This ensures the correct redistribution of participants across the defined bands.

## Output Fee vs. Service Fee

Example: How a price per participant of £1,000 is distributed between **Service Fees** and **Output Fees**:

### Output fees

Declarations are paid each time a declaration is submitted. Output fee’s make up 60% of the price per participant. This would equate to £600 in possible payments a lead provider could claim for subject to a participant training and a provide submitting an evidence of engagement via the API.

### Service fees

Are paid on a monthly basis over 2 years. The figures are based on the recruitment targets supplied by the lead provider. This would equate to around £400 in payments over the course of 24 months (£16.66) paid to lead provider for each participant trained.

### Breakdown of fees for ECTs:

### **Total Cost per ECT participant**: **£1,000**
- This cost is split into **Service Fees (40%)** and **Output Fees (60%)**.

### **1. Service Fee (£400, 40%)**
- This is paid to the provider **regardless** of participant performance.
- Distributed over time:
  - **90% paid over 29 months** for standard-length inductions.
  - **10% paid over 40 months** for non-standard-length inductions.

### **2. Output Fee (£600, 60%)**
- This is **performance-based** and only paid when participants reach specific training milestones.
- **Breakdown:**
  - **Start Payment**: **£120** (20% of Output Fee)
  - **Retention Payments**: **£90 each × 4 payments** (15% of Output Fee each)
  - **Completion Payment**: **£120** (20% of Output Fee)

### **3. Extension Payment (£90, 15% of Output Fee)**
- Additional payment if a participant requires **extra support** to complete training.

### **4. Conditions for Output Payments**
- **Suppliers must declare** that a participant has met a milestone before payments are made.
- If a mentor or participant does **not engage**, **some payments (like completion) may not be triggered**.

This pricing model ensures that providers receive a **fixed portion** (Service Fee) while incentivizing them to support participants through key training milestones (Output Fee). Additional payments are available for extended training support.

### Breakdown of fees for Mentors:

Unlike Early Career Teachers (ECTs), mentors are **only paid via Output Fees**, and pricing bands do not apply.

### **Total Cost per Mentor participant**: **£1,000**
- The full amount is allocated to **Output Fees**.

### **Output Fee Breakdown**
| Payment Type       | Percentage | Amount | Condition |
|--------------------|------------|---------|----------------------------------|
| **Start Payment**  | 50%        | £500    | Paid when a **mentor starts training** |
| **Completion Payment** | 50%   | £500    | Paid when a **mentor completes training** |


- Mentor payments are fully performance-based.
- No fixed service fee is included.
- Payments are only made when training milestones (**starting & completing**) are met.

## Contract manager logging in and viewing the bandings

A contract manager can log in to the service as a finance user and access participant declarations via the **search participant data** tab.

They can view details such as the:

- declaration type
- declaration date
- current state
- the last time the declaration was updated

A contract manager can also view all declarations that are due to be paid by accessing the financial statements as a finance user.

Contract managers can select the current training milestone and view the number of declarations, service fee, additional adjustments and clawbacks that are due to paid in the upcoming payment window.
