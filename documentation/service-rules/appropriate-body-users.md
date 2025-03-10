---
title: Appropriate bodies
---

Appropriate bodies [assure the quality of statutory teacher induction](https://www.gov.uk/government/publications/statutory-teacher-induction-appropriate-bodies/find-an-appropriate-body#role-of-appropriate-bodies).

They assure that:

* relevant people know of their responsibilities for monitoring support and assessment during teacher induction, and are capable of meeting them
* monitoring, support, assessment and guidance procedures in place are fair and appropriate

Appropriate bodies are responsible for informing DfE when:

* they accept new early career teachers into their care - internally this is referred to as _claiming an early career teacher_.
* an early career teacher in their care is released
* an early career teacher completes their induction
* extensions are added to an early career teacher's induction

## Signing in

Appropriate body users sign in with [DfE Sign-in](https://services.signin.education.gov.uk/), an [OpenID Connect](https://openid.net/developers/how-connect-works/)-based [single sign-on](https://en.wikipedia.org/wiki/Single_sign-on) service used by DfE.

The users, accounts, credentials and links to organisations are managed by DfE Sign-in, the application has no record of them.

### How signing-in works

1. a user visits the service and when they try to access a restricted page (i.e., by clicking the 'Start now' button) they are redirected to the DfE Sign-in login page
2. they enter their username and password and are then redirected back to the application with an [ID token param](https://jwt.io/) on the URL
3. we decode this token and it contains information on who the person is and which organsiation they're associated with, which looks something like the example below
4. we check our list of appropriate bodies for an `dfe_sign_in_organisation_id` that matches the `organisation->id`
5. we then call the [DfE Sign-in API](https://github.com/DFE-Digital/login.dfe.public-api?tab=readme-ov-file#get-roles-for-service) to ensure that the person has the role:
    * name: `Register ECTs`
    * code: `registerECTsAccess`
6. if they do, we've confirmed they are belong to the appropriate body and have the right access level, create a user session and redirect them to the appropriate body home page

Example user info returned by DfE Sign-in:

```
{
  "sub": "aaaaaaaa-aaaa-aaaa-1111-111111111111",
  "organisation": {
    "id": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
    "name": "Some appropriate body"
  },
  "given_name": "Clarissa",
  "family_name": "Darling",
  "email": "clarissa@nickelodeon.com"
}
```

#### When users aren't linked to an organisation
#### When users are linked to an organisation but don't have the right role


## Viewing early career teachers

### The current ECT list

When an appropriate body user logs in they'll see a list of their current ECTs.

They can search the list by name and TRN. When 7 digit numbers are detected in the search string they will take precedance over any text.

They can also [find and claim](#claiming-a-new-early-career-teacher) new ECTs by clicking the 'Find and claim an ECT' button.

Clicking on 'Show' in an ECT's summary card will take users to the [the view page for that ECT](#the-current-ect-view).

### The current ECT view

The view page shows details about the selected ECT, including their:

* TRN
* name
* extensions
* initial teacher training record summary
* a list of their induction periods

From this page the user can:

* [pass their induction](#passing-an-early-career-teacher-39-s-induction)
* [fail their induction](#failing-an-early-career-teacher-39-s-induction)
* [release the ECT](#releasing-an-early-career-teacher)

## Finding and claiming new early career teachers

When an appropriate body takes over the care of a early career teacher they inform us by registering them.

The registration process takes place with the following steps:

1. Identifying the teacher using the [TRS API](https://preprod.teacher-qualifications-api.education.gov.uk/swagger/index.html) using the following pieces of information:
    * [TRN](https://www.gov.uk/guidance/teacher-reference-number-trn)
    * Date of birth
2. Confirming the details returned by the TRS API belong to the person we expect, this page shows the teacher's:
    * name
    * date of birth
    * email address
    * [QTS](https://www.gov.uk/guidance/qualified-teacher-status-qts) award date
    * QTS status
    * induction start date
    * induction status
    * [initial teacher training](https://www.gov.uk/government/collections/initial-teacher-training) provider
    * initial teacher training end date
    * [alerts](https://www.gov.uk/government/collections/teacher-misconduct)
3. Asking for more details about the induction:
    * the date the ECT began their induction with the appropriate body
    * what induction programme type (FIP/CIP/DIY) they're doing

### Validation

* **TRN**
  - must be present
  - must be 7 numeric digits
* **Date of birth**
  - must be present
  - the teacher must be between 18 and 100 years old
* **Induction start date**
  - must be present
  - must be after the QTS award date
* **Induction programme**
  - must be either `fip`, `cip` or `diy` (enforced in the database)

### Early exits

#### Induction already completed

Early career teachers [have only one chance to complete their induction](https://ecf-service-manual.education.gov.uk/policy/induction-for-early-career-teachers/#para-1-13).

The exception is when teachers fail their induction [and then successfully appeal the decision](https://ecf-service-manual.education.gov.uk/policy/induction-for-early-career-teachers/#para-4-9). This is rare and we've decided to handle it manually for now.

#### No QTS

An early career teacher cannot begin their induction [until they have been awarded QTS](https://ecf-service-manual.education.gov.uk/policy/induction-for-early-career-teachers/#para-2-10).

#### Exempt from completing induction

#### Ongoing induction with another appropriate body

If the early career teacher has already been registered by an appropriate body, they cannot be registered by another.

The first appropriate body must [release them](#releasing-an-early-career-teacher) before the second can register them.

#### Prohibited from teaching

Teachers who have been prohibited from teaching aren't permitted to receive receive induction.

## Releasing an early career teacher

When an ECT finishes an induction at an appropriate body before they have fully completed their induction, the appropriate body informs DfE by releasing them.

The release process takes place with the following steps:

1. From the view ECT screen click 'Release'
2. Release the ECT by entering the following information:
    * The end date of the induction period
    * The number of terms carried out during the induction period
3. When submitted the current (open) induction period is updated with the provided end date and number of terms. This closes the induction period and leaves the ECT free to be claimed by another appropriate body.

### Validation

* **Induction period end date**
  - must be present
  - must be later than the induction start date
  - must not overlap with another induction period
* **Number of terms**
  - must be present
  - partial terms must be entered as decimals
  - value must be between 0 and 16 weeks

## Passing an early career teacher's induction

Most inductions end successfully. When the induction is complete the appropriate body informs DfE by recording a pass.

The pass process takes place with the following steps:

1. From the view ECT screen click 'Pass induction'
2. Pass the ECT by entering the following information:
    * The end date of the induction period
    * The number of terms carried out during the induction period
3. When submitted the current (open) induction period is updated with the provided end date and number of terms. This closes the induction period. The 'Pass' state and induction completion date are written to the teacher's record via the TRS API.

### Validation

* **Induction period end date**
  - must be present
  - must be later than the induction start date
  - must not overlap with another induction period
* **Number of terms**
  - must be present
  - partial terms must be entered as decimals
  - value must be between 0 and 16 weeks

## Failing an early career teacher's induction

Some inductions end unsuccessfully. When the induction is complete the appropriate body informs DfE by recording a fail.

The fail process takes place with the following steps:

1. From the view ECT screen click 'Fail induction'
2. Fail the ECT by entering the following information:
    * The end date of the induction period
    * The number of terms carried out during the induction period
3. When submitted the current (open) induction period is updated with the provided end date and number of terms. This closes the induction period. The 'Pass' state and induction completion date are written to the teacher's record via the TRS API.

### Validation

* **Induction period end date**
  - must be present
  - must be later than the induction start date
  - must not overlap with another induction period
* **Number of terms**
  - must be present
  - partial terms must be entered as decimals
  - value must be between 0 and 16 weeks

## Extensions

An ECT's induction must be extended if it is [interrupted by more than 30 working days for ad hoc purposes](/policy/induction-arrangements-for-school-teachers-in-england#para-8-1).

An ECT's induction may be extended if:
- It is interrupted by statutory maternity, paternity, adoption, shared parental, parental bereavement or carer’s leave
- The ECT is determined not to have met the Teaching Standards when they were due to complete their induction, and an Appropriate Body makes a decision that an extension to their induction is appropriate.

Appropriate Bodies only need to record the latter type of extension on the service, where an induction has been extended due to the ECT failing to meet the Teaching Standards. ECTs are able to appeal this type of extension.


Extensions are recorded at the teacher level, **induction periods are not extended**.

The extension record just holds the number of terms.

The number of terms value refers to full time equivalent (FTE) terms.

The number of extensions must be:
  - present
  - a numeric value
  - between 0.1 and 16 (used to keep the value sensible, not a policy-enforced limit)
  - 0 or 1 decimal place (1 and 1.5 are valid, 1.25 is not)

There is no validation preventing a teacher having an unlimited number of extensions.

### Viewing extensions

When an ECT has extensions the view ECT screen displays the sum of all extensions and has a 'View' link that takes you to the extensions page.

When an ECT has no extensions the view ECT screen shows 'None' and has a 'Add' link that takes you to the extensions page.

### Adding an extension

1. From the view ECT screen click 'Add' or 'View' in the 'Extensions' row
2. Click the 'Add extension' button
3. Enter a number in the 'Number of terms' field. The number must adhere to the validation rules above.
4. Click 'Add extension'

### Editing an extension

1. From the view ECT screen click 'Add' or 'View' in the 'Extensions' row
2. Click the 'Edit' link next to the extension you intend to modify
3. Enter a number in the 'Number of terms' field. The number must adhere to the validation rules above.
4. Click 'Update extension'
