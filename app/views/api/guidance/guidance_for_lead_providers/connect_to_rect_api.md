---
title: Connect to the RECT API
sidebar_position: 14
---
A unique API token is needed to connect to the register early career teachers API.

Each token is associated with a single provider and will give lead providers access to information about ECTs and mentors they are training, or have trained.


## Request an API token

Lead providers must contact us via email or their Teams channel to request a new token for production and sandbox environments. API tokens are distributed via Galaxkey and do not expire.

Providers must not share tokens in publicly accessible documents or repositories.

## How to use an authentication token

Include an authentication token in all requests to the API by adding an Authorization request header (not as part of the URL) in the following format:

`Authorization: Bearer {token}`

Unauthenticated requests will receive an UnauthorizedResponse with a 401 error code.

## Access YAML format API specs

Provider development teams can also access the OpenAPI spec in YAML format:

`https://www.register-early-career-teachers.education.gov.uk/api/docs/v3/swagger.yaml`

Providers can use API testing tools such as [Postman](https://www.postman.com) to make test API calls. Providers can import the API as a collection by using Postman's import feature and copying in the YAML URL of the API spec.

## Production and sandbox environments

The API is available via production (live) and sandbox (testing) environments.

### Production environment

The production environment is the live environment which processes real data.

Do not perform testing in the production environment as real participant and payment data may be affected.

`https://www.register-early-career-teachers.education.gov.uk/api/v3`

### Sandbox environment

The sandbox environment is used to test API integrations without affecting real data.

`https://sandbox.register-early-career-teachers.education.gov.uk/api`

There are some custom API headers that can only be used in the sandbox, such as `X-With-Server-Date`, which allows for [testing the ability to submit declarations in the sandbox ahead of time](/api/guidance/guidance-for-lead-providers/how-to-test-the-api-effectively#test-declaration-submissions-using-x-with-server-date).

Visit our [API testing guidance](/api/guidance/guidance-for-lead-providers/how-to-test-the-api-effectively) for further information on testing the API.
