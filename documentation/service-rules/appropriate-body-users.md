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

The users, accounts, credentials and links to organisations are managed by DfE Sign-in, the application does not save their account details.

When they make changes in the system, the name and email address of the user is stamped on an event record for auditing purposes.

### How signing-in works

1. appropriate body users who visit our service are directed to log in with [DfE Sign-in](https://services.signin.education.gov.uk/)
2. when they're redirected back to us we receive a `organisation.id` which we use to find their appropriate body by matching it to the `dfe_sign_in_organisation_id` field in our database
3. we call the [DfE Sign-in API](https://github.com/DFE-Digital/login.dfe.public-api?tab=readme-ov-file#get-roles-for-service) to ensure they have the role `AppropriateBodyUser` in the service `Register ECTs`
4. if they do they're allowed to access the service

### Example user info returned by DfE Sign-in

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

### When there is no matching organisation or role

When the `dfe_sign_in_organisation_id` is blank the user will be redirected to the 'access denied' page with [information on how to request access to an organisation](https://github.com/DFE-Digital/register-early-career-teachers-public/blob/5ee0dc66c4a70f0a1bd86ecb329eac2947644550/app/views/pages/access_denied/_without_organisation.md.erb).

When the `dfe_sign_in_organisation_id` is present but the user doesn't have the `AppropriateBodyUser` role, they will be redirected to the 'access denied' page with [information on how to request the right role](https://github.com/DFE-Digital/register-early-career-teachers-public/blob/5ee0dc66c4a70f0a1bd86ecb329eac2947644550/app/views/pages/access_denied/_with_organisation.md.erb).

## Viewing early career teachers

When an appropriate body user logs in they'll see:

* links to find and claim new ECTs
* links to record outcomes for existing ECTs
* a link to check data submitted by schools
* a list of current ECTs claimed by the appropriate body, searchable by name or TRN

## Claiming early career teachers

Appropriate bodies must inform us they are taking responsibility for an early career teacher's induction by claiming them.

Claiming an early career teacher opens an `InductionPeriod` for that teacher. Teachers can only have one induction period at a time.

There are two ways to claim an early career teacher:

### Claiming a single early career teacher

The claim process is started by clicking 'Find and claim a new ECT' from the appropriate body home page.

It has 3 steps:

1. finding the teacher's record using their TRN and date of birth
2. confirming the teacher's details are correct
3. entering the date the appropriate body took responsibility for the teacher's induction and the induction programme type

### Claiming multiple early career teachers at once

Lots of appropriate bodies use third party software to manage their ECTs. They can avoid having to claim their ECTs one at a time by uploading a CSV.

The process is started by clicking 'Claim multiple ECTs' from the appropriate body home page.

Before they start they need to have compiled a CSV file using [the provided template](https://github.com/DFE-Digital/register-early-career-teachers-public/blob/main/public/bulk-claims-template.csv?plain=1).

#### Example CSV

```csv
"TRN","Date of birth","Induction programme","Induction period start date"
1234567,"1990-01-01","provider_led","2024-09-01"
2345678,"2001-02-02","school_led","2025-10-01"
```

### Validation

* **TRN**
  - must be present
  - must be 7 numeric digits
* **Date of birth**
  - must be present
  - the teacher must be between 18 and 100 years old
* **Induction period start date**
  - must be present
  - must be after the teacher's QTS award date
* **Induction programme**
  - must be present
  - must be either `provider_led` or `school_led`

### Invalid claims

Some ECTs cannot be claimed. The reasons are:

#### Induction already completed

Early career teachers [have only one chance to complete their induction](https://register-ects-service-manual.education.gov.uk/policy/induction-for-early-career-teachers/#para-1-13).

The exception is when teachers fail their induction [and then successfully appeal the decision](https://register-ects-service-manual.education.gov.uk/policy/induction-for-early-career-teachers/#para-4-9). This is rare and we've decided to handle it manually for now.

#### No QTS

An early career teacher cannot begin their induction [until they have been awarded QTS](https://register-ects-service-manual.education.gov.uk/policy/induction-for-early-career-teachers/#para-2-10).

#### Exempt from completing induction

#### Ongoing induction with another appropriate body

If the early career teacher has already been registered by an appropriate body, they cannot be registered by another.

The first appropriate body must [release them](#releasing-an-early-career-teacher) before the second can register them.

#### Prohibited from teaching

Teachers who have been prohibited from teaching aren't permitted to receive induction.

## Passing, failing and releasing early career teachers

All early career teachers that have an ongoing `InductionPeriod` will be listed on the appropriate body's home page.

The `InductionPeriod` can be finished in one of three ways:

1. **release** - the appropriate body is no longer responsible for the teacher's induction
2. **passing** - the teacher has successfully completed their induction
3. **failing** - the teacher wasn't successful in their induction (this happens **very rarely**, a few times per year)

All of them follow a similar process and need:

1. the date the induction period ended (the day the teacher was released, passed or failed)
2. the number of full time equivalent (FTE) terms the teacher completed

### Releasing an early career teacher

Releasing an early career teacher:

* finishes their current induction period
* removes them from the appropriate body's list of ECTs

It doesn't affect the teacher's record in the TRS.

Once the teacher has been released, they can be claimed by another appropriate body.

### Passing an early career teacher's induction

Marking an early career teacher as having passed their induction:

* finishes their current induction period
* removes them from the appropriate body's list of early career teachers
* updates their record in the TRS and sets their induction status to `Passed` and their completion date to the current day

Once the teacher has passed they cannot be claimed by another appropriate body.

### Failing an early career teacher's induction

Marking an early career teacher as having failed their induction:

* finishes their current induction period
* removes them from the appropriate body's list of early career teachers
* updates their record in the TRS and sets their induction status to `Failed` and their completion date to the current day

The failure process has two additional questions:

* has the teacher been notified that they have failed their induction?
* when was the teacher notified that they have failed their induction?

Once the teacher has failed they cannot be claimed by another appropriate body.

### Validation

* **Induction period end date**
  - must be present
  - must be later than the period's start date
* **Number of terms**
  - must be present
  - must have a maximum of 1 decimal place
  - must be between 0.1 and 16
* **Teacher has been notified of failure** (failure only)
  - must be checked
* **Date teacher was notified of failure** (failure only)
  - must not be in the future
  - must be on ot after the induction period end date

### Releasing or passing multiple early career teachers at once

Appropriate Bodies can upload files and process multiple claims, outcomes or releases at a time using a CSV file.

Files must:

- use the provided CSV template
- contain between 1-1000 rows
- not exceed 100KB
- use the date format `YYYY-MM-DD`
- identify ECTs using date of birth and TRN
- not contain duplicate TRNs
- satisfy existing validation criteria for induction periods


#### Example CSV

```csv
TRN,Date of birth,Induction period end date,Number of terms,Outcome
1234567,"1990-01-01","2025-04-04",2,release
2345678,"2001-02-02","2026-10-10",6,pass
```


#### Errors

Optionally, an `Error message` column is supported.
Unprocessable ECTs can be downloaded as a CSV with actionable feedback on why the task was not completed.

## Extensions

An ECT's induction [must be extended](https://register-ects-service-manual.education.gov.uk/policy/induction-for-early-career-teachers/#para-3-6) when it is interrupted by 30 or more FTE working days in a year.

Extensions are recorded at the teacher level as a number of FTE terms, **induction periods are not extended**.

Extension data is not sent to the TRS.

Once added, extensions can be edited but not deleted.

### Validation

* **Number of FTE terms**
  - must be present
  - must be a numeric value
  - must be between 0.1 and 16 (used to keep the value sensible, not a policy-enforced limit)
  - must have 0 or 1 decimal place (`1` and `1.5` are valid, `1.25` is not)

There is no limit to the number of extensions a teacher can have.
