---
title: Using the API sandbox
---

Use this guidance to understand: 

* what the sandbox is for
* why it's helpful to use the sandbox before going live
* how to access and start using it 

## What is the sandbox? 

The sandbox is a safe, test version of the live service. It lets lead providers try out the 'Register early career teachers' API functionality without affecting real data or triggering any actions in the live system. 

Lead providers can use the sandbox to: 

* explore the API and test their integration
* simulate common tasks (such as submitting declarations or changing participant schedules)
* check how their system handles responses from the service
* prepare for live data submissions with confidence
* test new functionality and give us feedback before it goes live

The sandbox works just like the live environment, but no real training records, payments, or notifications are sent. 

To help get started, we recommend that technical teams bookmark the [Swagger API documentation](/api/docs/v3) so they can quickly find the latest information about endpoints, request formats, and validation rules.

## Benefits of using the sandbox 

Using the sandbox helps lead providers: 

* test new and existing features safely by experimenting with data and functionality without risk to live records or triggering real-world consequences
* build confidence by verifying their integration works as expected before going live
* reduce errors by spotting and fixing issues early to avoid delays or data problems in the live system
* understand user journeys by simulating common actions (like deferring a participant) to understand how they work in practice
* train their team by giving staff a risk-free environment to learn how to use the service and test workflows 

## Access the sandbox 

### 1. Use the API authentication token credentials 

Lead providers should contact the DfE support team or their account manager to request sandbox access if they do not already have it.  

They'll receive: 

* a unique sandbox authentication token
* example credentials and test data 

### 2. Use the sandbox URL 

The [sandbox runs on a separate domain](https://sandbox.register-early-career-teachers.education.gov.uk/api) from the live service. 

### 3. Check your setup 

Once lead providers have connected their system to the sandbox, they can: 

* send test data to endpoints
* simulate common user journeys
* receive mock responses 

Things to keep in mind: 

* the sandbox is for testing only, so only data entered will be saved or used in the live system
* providers will need separate credentials from their live environment
* test data may be refreshed or reset at any time
  
## Access YAML format API specs 

Lead provider development teams can also access the OpenAPI spec in a YAML format: [View the OpenAPI v3.0.0. spec](/api/docs/v3/swagger.yaml)

They can use API testing tools such as [Postman](https://www.postman.com/) to make test API calls. Lead providers can import the API as a collection by using Postman's import feature and copying in the YAML URL of the API specification. 
