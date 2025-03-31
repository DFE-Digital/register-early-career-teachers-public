---
title: Finance users
---

Financial statements are monthly record of payments made to lead providers. They are generated based on the declarations submitted by lead providers, which are attached to a specific statement depending on the timing of submission and applicable funding criteria. Each statement provides a complete picture of the payments for that period, including a summary, detailed breakdowns, and total amounts. These totals may include output payments, clawbacks, VAT, service fees, and any additional one-off adjustments.

## Contents

[Attach declaration to a financial statement](#attach-declaration-to-a-financial-statement)

[View financial statement](#view-financial-statement)

[Download statement declarations](#download-statement-declarations)

[Authorise statement for payment](#authorise-statement-for-payment)

[Additional adjustments](#additional-adjustments)

[Contract information](#contract-information)

[Statement versioning](#contract-information)

## Attach declaration to a financial statement

When a lead provider submits a declaration via the `POST /api/v[1,2,3]/participant-declarations` endpoint, the declaration is attached to the next _output fee_ financial statement, provided the participant is fundable and the declaration is not a duplicate.

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

## View financial statement

Financial statements are generated dynamically when visiting the **View financial statements** page in the **DfE Finance** dashboard.

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

The following data is used to generate a statement:

- Declarations (including clawbacks)
- Call off contract
- Mentor call off contract
- Adjustments

Statement values are calculated using the `Finance::ECF::StatementCalculator`.

There are two versions of statements:

- **Cohorts up to 2024** – values for ECTs and Mentors are combined
- **Cohorts from 2025 onwards** – values for ECTs and Mentors are separated

Declarations are submitted by lead providers.
Call off contract and mentor call off contract information is provided by contract managers.
Adjustments are also added by contract managers.

## Download statement declarations

The financial statement page includes a **Download declarations (CSV)** link. This allows finance users to download a full list of all declarations used in the statement.

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

## Authorise statement for payment

A statement can be marked as paid if:

- `output_fee` is `true`
- `state` is `payable`
- `marked_as_paid_at` is `nil`
- `deadline_date` is in the past
- It contains declarations

Statements are automatically marked as payable by a daily cron job once the `deadline_date` has passed.

If all the above conditions are met, an **Authorise for payment** button is shown on the financial statement page.

Once a statement is marked as paid:

- The button is replaced with `Authorised for payment at {marked_as_paid_at}`
- Adjustments can no longer be edited
- Declarations can no longer be attached to that statement

## Additional adjustments

Statements with `output_fee` set to `true` can include additional one-off adjustments. These can be positive or negative, e.g. backdated service fees.

A breakdown of adjustments appears at the bottom of the financial statement page, and the total adjustment value is shown in the summary section at the top.

Adjustments cannot be edited after the statement has been marked as paid.

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

## Contract information

Contract managers can view contract values used for statement calculation by clicking the **Contract information** link at the bottom of the financial statement page.

A contract is identified by the lead provider, cohort and version. Contracts are not shared by lead providers or cohort.
Statements from the same lead provider and cohort can share the same contract (identified by `contract_version`).

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

## Statement versioning

Statements include a `contract_version` field, which determines which version of the call off contract to use in the statement calculator. This value follows **semantic versioning**, starting from `0.0.1`.

When contract values are updated:

- The existing contract and its bands are duplicated
- New contract values and band values are applied
- The contract `version` is incremented (patch version)
- The statement’s `contract_version` is updated to match the new contract version

Contracts that are no longer linked to statements (due to it being superseded by new contract version) or identified as duplicates have their `version` prefixed with `unused_` (e.g. `unused_0.0.1`) to indicate they should not be used for statement calculations.
