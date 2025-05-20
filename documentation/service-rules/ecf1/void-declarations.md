---
title: Lead provider API
---

This document outlines the process and implications of voiding participant declarations within the Early Career Framework (ECF) programme. It is intended for Lead providers interacting with the ECF API and internal DfE Finance team.

This documentation describes:

- What voiding means within the ECF service
- Who can void a declaration and how
- Validation rules and error messages
- How voided declarations are displayed and reported

## Contents

[Definition of voiding](#definition-of-voiding)

[Impact of voiding on declaration states](#impact-of-voiding-on-declaration-states)

[Impact of awaiting clawback on statement attachment](#impact-of-awaiting-clawback-on-statement-attachment)

[Interactions](#interactions)

[Lead provider voiding declarations](#lead-provider-voiding-declarations)

[Error handling](#error-handling)

[Lead provider viewing declarations](#lead-provider-viewing-declarations)

[Finance users](#finance-users)

[Frozen cohorts and statements](#frozen-cohorts-and-statements)

## Definition of voiding

**Voiding** is a mechanism that allows a Lead provider or a DfE Finance user to retract or cancel a previously submitted participant declaration.

* When a declaration is made, it is typically associated with the current open statement or the next upcoming statement, depending on its submission date and the statement cut-off dates. This ensures that providers are compensated for the services they have delivered within that statement period. The `statement_id` attribute within a declaration's data (as seen in the API response) indicates which statement the declaration is currently attached to. Initially, when a declaration is submitted and deemed eligible, it will be assigned to an active statement for payment processing.
* Voiding a declaration is necessary in various scenarios, such as correcting errors, ineligible participants, responding to changes in participant circumstances, or when a declaration was made incorrectly.
* A `voided` declaration is effectively cancelled and will not be used in invoicing or funding calculations.
* Once a declaration is voided, it cannot be restored and must be re-submitted if appropriate.
* A `voided` declaration will not be soft-deleted.

## Impact of voiding on declaration states

When a declaration is voided, its resulting state depends on the state it was in prior to the void action:

* **Submitted, Eligible, Payable:** If a declaration is in a `submitted`, `eligible`, `payable` or `ineligible` state, voiding it will transition the declaration to a `voided` state with no further action required. It effectively nullifies the declaration. The declaration won't appear as a `payable` item and remains associated with the same statement it was originally on. It is not moved to a different statement. It will be marked as `voided` on any internal DfE listings or reports related to its original intended statement period.
* **Paid:** If a declaration has already been `paid`, voiding it will transition the declaration to an `awaiting_clawback` state. This signifies that the funds paid out for this declaration need to be recouped by DfE, typically by being deducted from a future statement to the Lead provider. The declaration is then moved to that future statement which is the latest open output statement for the Lead provider. By the time DfE "freezes" that next available financial statement, declarations in `awaiting_clawback` state, will transition to `clawed_back`.

## Impact of awaiting clawback on statement attachment

As mentioned above, when a paid declaration is `voided`, it enters an `awaiting_clawback` state. The key point here is its attachment to statements:

* The declaration is marked for clawback.
* It is attached to the latest output statement (or the next one to be generated) via the `clawback_statement_id`. This ensures that the overpayment is reconciled in the upcoming payment cycle.

This distinction is important: for a non-paid voided declaration, the state will be `voided`, and the `statement_id` will remain the original statement, and `clawback_statement_id` will be null, while for a paid-then-voided declaration (`awaiting_clawback`), it is effectively moved to the newest statement for the purpose of financial reconciliation (the clawback) and the `clawback_statement_id` field would be populated with the ID of the statement on which the clawback will be processed.

This mechanism ensures accurate financial accounting, allowing the DfE to manage payments and reclaim funds correctly when declarations are voided after payment has occurred.

## Interactions

Several user roles interact with the voiding functionality:

* **Lead providers void a declaration:** Primarily done via the ECF API.
* **Finance user voids a declaration:** Done through the internal DfE finance application.
* **Finance user views voids in the drill down:** Voided declarations are visible within detailed participant views in the finance system.
* **Finance user views voids in the output statements:** Voided declarations and clawbacks are reflected in financial statements.

## Lead provider voiding declarations

Lead providers can void a declaration by making a `PUT` request to the ECF API:

```
PUT /api/v[1,2,3]/participant-declarations/{id}/void
```

**Required details:**

- `id`: the unique identifier of the declaration to be voided

Example request:

```
PUT /api/v[1,2,3]/participant-declarations/db3a7848-7308-4879-942a-c4a70ced400a/void
```

#### Successful response

- Upon successful voiding, the API will typically return a 200 OK HTTP status code.
- The response body will usually contain the full JSON representation of the declaration, now updated to reflect its new state (e.g., `voided` or `awaiting_clawback`). This allows the Lead provider to confirm the change immediately.

Example response:

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
  ]
}</code></pre>

## Validation rules

Before a declaration can be marked as `voided`, the following checks are performed:

- **Eligibility**: Only declarations in states `submitted`, `eligible`, `payable`, or `paid` are eligible for voiding. It is not possible to void a declaration that is already in a `voided` or `clawed_back` state.
- **Paid declarations**: Paid declarations will be marked as `awaiting_clawback` first until a claw-back is processed. Then it will be marked as `clawed_back`.
- **Validation against Statement**: Voided declarations are mapped to the original statement for financial records and audit trail.

## Error handling
  - For Lead providers (API):
    - 404 Not Found: If the declaration ID provided in the URL does not exist.
    - 422 Unprocessable Entity: This is a common error code used by the ECF API when a request is syntactically correct but semantically incorrect (i.e., the action cannot be performed due to business rules). This would be returned if:
      - The declaration is not in a voidable state (e.g., already `voided`, `clawed_back`)
    - Other 4xx client error codes or 5xx server error codes might be returned for other issues (e.g., authentication problems, unexpected server errors, too many requests).
  - For Finance Users (Finance App):
    - Error messages will be displayed within the finance application's user interface. These messages will aim to be user-friendly, explaining why the void cannot be processed (e.g., "This declaration has been clawed-back, so you can only view it." or "This declaration has already been voided.").

## Lead provider viewing declarations

Lead providers can view the status of their declarations, including those that have been voided, by using the GET endpoint.

```
GET /api/v3/participant-declarations
```

### Query parameters

* `filter[participant_id]` (optional): Filter declarations by a specific participant's ID.

* `filter[updated_since]` (optional): Filter declarations updated since the specified ISO 8601 timestamp.

* `page[page]` (optional): Specify the page number for pagination.

* `page[per_page]` (optional): Specify the number of results per page.

#### Example request

```
GET /api/v3/participant-declarations?filter[participant_id]=ab3a7848-1208-7679-942a-b4a70eed400a&filter[updated_since]=2020-11-13T11:21:55Z&page[page]=1&page[per_page]=5
```

## Finance users

### Searching and voiding

- Search for a participant in the finance dashsboard
- Only declarations eligible for voiding will display a **"Void"** button
- The user is prompted with a confirmation (Check Your Answers) screen
- On confirmation, the declaration is marked as voided and status is updated

### Reviewing voided declarations

- Voided declarations are visible in the finance drill-down/admin dashboard
- Can be reviewed for auditing and reconciliation
- A CSV file can also be downloaded with the details of all declarations linked to a specific statement via the button "Download declarations (CSV)"

### Viewing voided declarations in output statements

Finance users can view all voided declarations in the output statement interface:

1. **Navigate to statements:** Go to the finance statements section.
2. **Select a statement:** Choose the desired funding statement.
3. **Voids count:** Any voids are displayed in the dedicated "Voided" column.
4. **Voided declarations page:** Voided declarations can be reviewed clicking on the dedicated "Voided" column count.

## Frozen cohorts and statements

- When DfE "freezes" a financial statement for assurance tasks, declarations on that statement that are `payable` transition to `paid` and `awaiting_clawback` declarations transition to `clawed_back`.
- Lead providers are generally blocked from directly voiding declarations that are in a paid state, if the associated statement period is closed or "frozen". This is because the payment has been processed and reconciliation is more complex. In this case an error message is returned from the API: `"You cannot submit or void declarations for the 2021 cohort. The funding contract for this cohort has ended. Get in touch if you need to discuss this with us"`.
- Why LPs are unable to void declarations on frozen cohorts: Once a cohort's financial data is finalised and statements are closed (payments made), direct voiding by LPs is restricted to maintain financial integrity. If a declaration from a frozen cohort needs to be voided (e.g., an error is discovered late), it will require an investigation on a case by case basis and may result in manual adjustment and the contract is closed after the final output statement. Lead providers are unable to void declarations that are associated with frozen cohort as there are no output statements in the cohort to claw it back from.
- In scenarios like cohort closures (e.g., the 2021 cohort closure), DfE may provide specific guidance for managing declarations, which can include moving participants to new cohorts. If an incorrect declaration was made in a new cohort during such a transition, the Lead provider might need to void that new declaration to allow for correct declaration in the old cohort, sometimes with DfE support.
