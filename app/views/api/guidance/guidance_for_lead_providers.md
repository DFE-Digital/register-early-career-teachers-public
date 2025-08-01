---
title: Guidance for lead providers
---

Use this guidance to: 

* understand lead providers responsibilities
* know how lead providers should interact with the Department for Education (DfE) and the ‘Register early career teachers’ service
* find where to manage data, funding and reporting 

## What lead providers are responsible for 

Lead providers are responsible for delivering high-quality early career teacher (ECT) training based on the initial teacher training and early career framework. This includes: 

* coordinating with delivery partners and schools
* ensuring ECTs and mentors receive the full programme entitlement
* submitting timely, accurate data to DfE
* managing changes to participant details and training status
* making sure declarations are correct so funding can be released 

## Where to manage participant training data 

Lead providers must use the [‘Register early career teachers’ API](/api) to submit and update data about:

* early career teachers
* mentors
* training schedules
* programme declarations
* participant deferrals, withdrawals and reinstatements
* creating and updating partnerships

This data enables: 

* delivery of training
* accurate payments
* oversight of participant progress 

## Testing and going live 

Lead providers should use the [sandbox environment](https://sandbox.register-early-career-teachers.education.gov.uk/api) to test sending data before moving to production when it goes live. This will help ensure: 

* their integration works correctly
* errors can be fixed early
* payments are not delayed due to data issues 

[Read the sandbox guidance](/api/guidance/sandbox)

The sandbox works just like the live environment, but no real training records, payments, or notifications are sent. 

To help get started, we recommend technical teams bookmark the [Swagger API documentation](/api/docs/v3) so they can quickly find the latest information about endpoints, request formats, and validation rules.

## Other interactions with DfE 

In addition to managing training data, lead providers may also need to: 

* submit reports and quality assurance data
* respond to DfE communications or data checks
* access funding statements and programme documentation
* collaborate with appropriate bodies on ECT progress and assessment 

They’ll typically hear from DfE through: 

* emails
* Slack messages 

DfE also publishes [release notes](/api/guidance/release-notes) whenever it updates the API.
