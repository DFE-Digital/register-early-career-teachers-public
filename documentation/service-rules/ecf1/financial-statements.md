---
title: Financial Statements
---

Financial statements are monthly record of payments made to lead providers. It is generated based on the declarations submitted by lead providers, which are assigned to a specific statement depending on the timing of submission and applicable funding criteria. Each statement provides a complete picture of the payments for that period, including a summary, detailed breakdowns, and total amounts. These totals may include output payments, clawbacks, VAT, service fees, and any additional one-off adjustments.

---

## How declarations are assigned to a statement

When a lead provider submits a declaration via the `POST /api/v[1,2,3]/participant-declarations` endpoint, the declaration is assigned to the next _output fee_ financial statement—provided the participant is fundable and the declaration is not a duplicate.

The _next output fee statement_ is determined as the first statement where:

- `output_fee` is `true`
- `deadline_date` is in the future
- Ordered by `deadline_date ASC`

Lead providers can check submitted declarations using the `GET /api/v[1,2,3]/participant-declarations` endpoint.

Contract managers and product team members can check by:

- Logging in as a user with the `finance` role
- Visiting the **DfE Finance** dashboard
- Navigating to the **Search participant data** page
- Entering the participant ID or declaration ID
- Scrolling down to the **Declarations** section, which lists all submitted declarations

---

## How statements are generated

Financial statements are generated dynamically when visiting the **View financial statements** page in the **DfE Finance** dashboard.

The following data is used to generate a statement:

- Declarations (including clawbacks)
- Call off contract
- Mentor call off contract
- Adjustments

Statement values are calculated using the `Finance::ECF::StatementCalculator`.

There are two versions of statements:

- **Cohorts up to 2024** – values for ECTs and Mentors are combined
- **Cohorts from 2025 onwards** – values for ECTs and Mentors are separated

Declarations are submitted by lead providers. Call off contract and mentor call off contract information is provided by contract managers. Adjustments are also added by contract managers.

---

## How to view statements

To view a financial statement:

- Log in as a user with the `finance` role
- Visit the **DfE Finance** dashboard
- Go to the **View financial statements** page
- Choose a lead provider
- The financial statement will be displayed

You can use the dropdowns to filter and view different statements:

- Select a lead provider
- Select a cohort
- Select a statement month
- Click the **View** button

---

## Downloading declarations (granular view)

The statement page includes a **Download declarations (CSV)** link. This allows users to download a full list of all declarations used in the statement.

The CSV includes the following fields:

- Participant ID
- Participant Name
- TRN
- Type
- Mentor Profile ID
- Schedule
- Eligible for Funding
- Eligible for Funding Reason
- Sparsity Uplift
- Pupil Premium Uplift
- Sparsity and PP
- Lead Provider Name
- Delivery Partner Name
- School URN
- School Name
- Training Status
- Training Status Reason
- Declaration ID
- Declaration Status
- Declaration Type
- Declaration Date
- Declaration Created At
- Statement Name
- Statement ID
- Uplift Payable

---

## How to authorise statements for payment

A statement can be marked as paid if:

- `output_fee` is `true`
- `state` is `payable`
- `marked_as_paid_at` is `nil`
- `deadline_date` is in the past
- It contains declarations

If all the above conditions are met, an **Authorise for payment** button is shown on the statement page.

Once a statement is marked as paid:

- The button is replaced with `Authorised for payment at {marked_as_paid_at}`
- Adjustments can no longer be edited
- Declarations can no longer be assigned to that statement

---

## How to add adjustments to a financial statement

Statements with `output_fee` set to `true` can include additional one-off adjustments. These can be positive or negative, e.g. backdated service fees.

A breakdown of adjustments appears at the bottom of the statement page, and the total adjustment value is shown in the summary section at the top.

> **Note:** Adjustments cannot be edited after the statement has been marked as paid.

### To add an adjustment

- Visit the relevant statement page (`output_fee` must be `true`)
- Scroll down to **Additional adjustments**
- Click **Add**
- Enter the payment type and click **Continue**
- Enter the payment amount and click **Continue**
- Review the summary and click **Confirm and continue**
- Choose to add another adjustment or select **No** and click **Continue**

### To change an adjustment

- Visit the statement page
- Scroll to **Additional adjustments**
- Click **Change or remove**
- Click **Change** on the relevant adjustment
- Update the payment type and/or amount
- Click **Continue** and then **Confirm and continue**
- Click **Back** to return to the statement page

### To remove an adjustment

- Visit the statement page
- Scroll to **Additional adjustments**
- Click **Change or remove**
- Click **Remove** on the relevant adjustment
- Confirm and click **Continue**
- Click **Back** to return to the statement page

---

## Viewing contract information

Contract managers can view contract values used for statement calculation by clicking the **Contract information** link at the bottom of the statement page.

The information displayed depends on the cohort:

### Cohorts up to 2024

- Provider name
- Recruitment target
- Revised recruitment target (+2%)
- Uplift target
- Uplift amount
- Set-up fee
- Bands:
  - Band name
  - Minimum
  - Maximum
  - Payment per participant

### Cohorts from 2025 onwards

- ECT recruitment target
- Revised ECT recruitment target (+115%)
- ECT bands:
  - Band name
  - Minimum
  - Maximum
  - Payment per participant
- Mentor recruitment target
- Mentor payment per participant

---

## Statement versioning

Statements include a `contract_version` field, which determines which version of the call off contract to use in the statement calculator. This value follows **semantic versioning**, starting from `0.0.1`.

When contract values are updated:

- The existing contract is duplicated
- New values are applied
- The version is incremented (patch version)
- The statement’s `contract_version` is updated to match the new contract version
