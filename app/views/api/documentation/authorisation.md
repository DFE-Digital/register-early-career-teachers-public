---
title: Authorisation
---

## How authorization works

We use the open standard [OAuth 2.0](https://oauth.net/2/) with the [Authorization Code Grant](https://oauth.net/2/grant-types/authorization-code/). This standard lets your users give your application permission to interact with us without sharing their password.

We use [PKCE](https://oauth.net/2/pkce/), in order to prevent code injection and CSRF attacks in the Authorization Code flow.

A user from each Appropriate Body you work with __must__ authorise the use of your application before we can grant you a token to access the RIAB API on their behalf.

### PKCE code-verifier and code-challenge

PKCE works by having a random secret called a `code verifier`, and a `code challenge` that is derived from it. You send the `code challenge` with the authorization request, and send the `code verifier` when exchanging the code for a token. This ensures only the application that started the flow can complete it.

You can optionally include a `state` value.  This is a value you can use to maintain a state between the request and the callback.  If you include a `state` it will be returned to you in the callback after the client approves (or denies) the connection request.

### Access token

We will return a token for each Appropriate Body that authorises your application that you should keep securely.

The token is valid for **1 year** from date of issue. When the token expires, you can get a new one by going through the authorisation process again. We do not support refresh tokens.

### Credentials

Your credentials are your client ID and your client secret.

Credentials are used:

- to identify your application during each step of an OAuth 2.0 journey
- when you test your application with sandbox APIs

#### Client ID

Your client ID is a unique identifier we create for your application when we add you to the service.

#### Client secret

Client secrets are unique passphrases used to authenticate your application. They are known only to your application and the authorising server.

The client secret is the equivalent of a password and should not be stored in plain text. Only store an encrypted version of the client secret to reduce the chance of it being compromised.



## Before you start

We will need to have registered your application, your callback endpoints and provided you with a Client ID.

> [!NOTE]
>
> How is this done for new applications/vendors?





## Getting an OAuth 2.0 access token

The complete process of obtaining an access token is illustrated by this sequence diagram



```mermaid
sequenceDiagram
    actor User 
    participant Vendor as Application
    participant RIAB as RIAB Service
   
    User->>Vendor: Initiates connection to RIAB
    Vendor->>Vendor: Generate code-challenge
    Vendor-->>User: Redirect to /oauth/authorize
    User->>RIAB: GET /oauth/authorize
    Note over User,RIAB: [User not signed in to RIAB] sign-in via DfE Sign-in and then continues 
    RIAB->>RIAB: Validate request
    RIAB-->>User: Show authorisation request details
    User->>RIAB: Approve connection
    RIAB-->>User: Redirect to vendor callback
    User->>Vendor: GET /callback
    Vendor->>Vendor: Validate state
    Vendor->>RIAB: POST /oauth/token
    RIAB->>RIAB: Validate request and generate token 
    RIAB-->>Vendor: 200 OK with token payload
```



The process can be broken down into 3 steps:

### 1. Request authorization

1. Send your user to our authorize endpoint
2. The user is taken through the DfE Sign-In process (if not already authenticated)
3. We display the authorization request details to your user
4. The user is asked to grant your application the authority to access their data

This part of the process is illustrated by this sequence diagram

```mermaid
sequenceDiagram
    actor User
    participant Vendor as Application
    participant RIAB as RIAB Service
   
    User->>Vendor: Initiates connection to RIAB
    Vendor->>Vendor: Generate code-challenge
    Vendor-->>User: Redirect to /oauth/authorize
    User->>RIAB: GET /oauth/authorize
    Note over User,RIAB: [User not signed in to RIAB] sign-in via DfE Sign-in and then continues 
    RIAB->>RIAB: Validate request
    RIAB-->>User: Show authorisation request details
    

```

#### 1.1 Syntax

```
curl -X GET "https://[riab-service-uri]/oauth/authorize?\
response_type=code\
&client_id=[YOUR-CLIENT-ID]\
&appropriate_body_period_id=[USERS-APPROPRIATE-BODY-IDENTIFIER]\
&state=[STATE]\
&redirect_uri=[YOUR-REDIRECT-URI]\
&code_challenge=[CODE-CHALLENGE]\
&code_challenge_method=[CODE-CHALLENGE-METHOD]"
```

#### 1.2 Example

```
curl -X GET "https://sandbox.register-early-career-teachers.education.gov.uk/oauth/authorize?\
response_type=code\
&client_id=Hf8sfkiUkYp9I3_R10qSnZ2ZUvoa\
&appropriate_body_period_id=9def8316-1d33-4181-b0d5-59c34c4a03f5\
&state=30de877c-ee2f-15db-8314-0800200c9a66\
&redirect_uri=https://www.myservice.example.com/callback\
&code_challenge=E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM\
&code_challenge_method=S256"
```

> [!WARNING]
>
> Do not include your client secret in this request.

#### 1.3 Parameters


| Parameter                    | Description                                                  |
| :--------------------------- | :----------------------------------------------------------- |
| `response_type`              | The OAuth 2.0 response type. Currently the only acceptable value is `code`. |
| `client_id`                  | The Client ID for your application.                          |
| `appropriate_body_period_id` | The ID for the Appropriate Body making the connection        |
| `state` (optional)           | An opaque value used to maintain state between the request and callback and to prevent tampering as described in the [OAuth 2.0 specification](https://tools.ietf.org/html/rfc6749#section-10.12). This is passed back to your application via the `redirect_uri`. |
| `redirect_uri`               | The URI that we use to send users back to your application after successful (or unsuccessful) authorisation.  This must match one of the redirect URIs you specified when you created your application. |
| `code_challenge`             | The [PKCE](https://oauth.net/2/pkce/) `code_challenge` is used to ensure that the subsequently-issued access token is not intercepted. |
| `code_challenge_method`      | The [PKCE](https://oauth.net/2/pkce/) `code_challenge_method` is used to transform the `code_verifier` to the `code_challenge`. This must have a value of `S256`. |

##### 

### 2. Receive authorisation results

The process is shown in this diagram which continues from step 1

```mermaid
sequenceDiagram
    actor User
    participant Vendor
    participant RIAB as RIAB Service
   
    User->>RIAB: Approve connection
    RIAB-->>User: Redirect to vendor callback
    User->>Vendor: GET /callback
    Vendor->>Vendor: Validate state

```



You must create an endpoint in your application to receive the authorisation results. This endpoint must accept an HTTP GET request to the redirect URI you specified in step 1.

The user's browser will be redirected back to your endpoint once they have granted your application the requested authority.

Your endpoint must support the following query parameters:

| Parameter           | Description                                                  |
| :------------------ | :----------------------------------------------------------- |
| `code`              | The authorisation code, if authorisation is successful. This is a single-use token that will expire after 10 minutes. |
| `state`             | The value of the optional state parameter you provided in the authorisation request, whether authorisation is successful or not. |
| `error`             | A short identifier for the error such as `access_denied`, if authorisation failed or `invalid_request` if the request parameters are invalid |
| `error_description` | Human readable description of the error, if authorisation failed, for example, “User refused connection”. |



#### 2.1 Example redirects

Example of a redirect we issue after a successful authorisation:

```
https://www.myapp.example.com/callback?code=6589c5d9fc4b9872b1f9013583c2f39d&state=30de877c-ee2f-15db-8314-0800200c9a66
```

Example of a redirect we issue after an unsuccessful authorisation:

```
https://www.myapp.example.com/callback?error=access_denied&error_description=User+refused+connection&state=30de877c-ee2f-15db-8314-0800200c9a66
```

#### 2.2 Error scenarios

If the `client_id` or the `redirect_uri`do not match our records, we return HTTP error status `400` (Bad request) and do not redirect to your `redirect_uri`. 

If there are any other issues with your call to our authorisation endpoint, we return an HTTP error status to your `redirect_uri`.

| Error scenario                                               | HTTP status         | Error code                  | Error message                                                |
| :----------------------------------------------------------- | :------------------ | :-------------------------- | :----------------------------------------------------------- |
| Response Type is missing                                     | `400` (Bad Request) | `invalid_request`           | `response_type can't be blank`                               |
| Response Type is invalid                                     | `400` (Bad Request) | `unsupported_response_type` | `Response type is not included in the list`                  |
| Appropriate Body ID is missing                               | `400` (Bad Request) | `invalid_request`           | `appropriate_body_id can't be blank`                         |
| Appropriate Body ID does not match the signed-in user's organisation. | `400` (Bad Request) | `access_denied`             | `appropriate_body_period_id does not match the logged-in Appropriate Body` |
| Client secret was included in the request                    | `400` (Bad Request) | `invalid_request`           | `client_secret should NOT be present`                        |
| PKCE Code Challenge cannot be empty                          | `400` (Bad Request) | `invalid_request`           | `Code challenge can't be blank`                              |
| PKCE Code Challenge Method, must be S256                     | `400` (Bad Request) | `invalid_request`           | `Code challenge method is not included in the list`          |



### 3. Exchange authorisation code for access token

The process is shown in this diagram which continues from step 2. 

```mermaid
sequenceDiagram
    actor User
    participant Vendor
    participant RIAB as RIAB Service
   
    Vendor->>RIAB: POST /oauth/token
    RIAB->>RIAB: Validate request and generate token 
    RIAB-->>Vendor: 200 OK with token payload
```



When you receive the authorisation code, you must exchange this for an access token **within 10 minutes**.

Do this via a HTTP POST to our token endpoint.

You must authenticate the request with [HTTP Basic Authentication](https://www.rfc-editor.org/info/rfc7617/) using your client ID and secret.  This takes the form of a HTTP header in which you Base64 encode your credentials in the form `client_id:client_secret`.  For example, if your client ID was `client123` and your secret was `supersecretvalue` then your Basic Authentication header would be this:

```
Authorization: Basic Y2xpZW50MTIzOnN1cGVyc2VjcmV0dmFsdWU=
```


>  [!WARNING]
>
>  Do not include your client ID or client secret in the body of the request.



Include the other parameters in the request body, not as additional request headers.

The example URLs shown below are for the sandbox environment only. In the production environment you should use https://register-early-career-teachers.education.gov.uk/

#### 3.1 Example request

```
curl -X POST https://sandbox.register-early-career-teachers.education.gov.uk/oauth/token \
--user "client123:supersecretvalue" \
-H "content-type:application/x-www-form-urlencoded" \
--data \
"grant_type=authorization_code\
&redirect_uri=[YOUR-REDIRECT-URI]\
&code=[AUTHORIZATION-CODE]" \
&code_verifier=[CODE-VERIFIER]"

```

| Parameter       | Description                                                  |
| :-------------- | :----------------------------------------------------------- |
| `grant_type`    | The OAuth 2.0 grant type. Currently the only acceptable value is `authorization_code` |
| `redirect_uri`  | The same redirect URI you used to call the authorisation endpoint.  For more details see our [reference guide](https://developer.service.hmrc.gov.uk/api-documentation/docs/reference-guide#redirect-uris). |
| `code`          | The authorisation code you received from us in the previous step. |
| `code_verifier` | Your [PKCE](https://oauth.net/2/pkce/) `code_verifier`       |

The response contains the access token as a JSON payload.   The access token is the equivalent of your password to access the API as the Appropriate Body that has authorised the request.  As such you should store it securely.

#### 3.2 Example response

A successful response will return HTTP status code `201` to indicate your token was created and a JSON payload containing the access token

```json
{
  "access_token": "QGbWG8KckncuwwD4uYXgWxF4HQvuPmrmUqKgkpQP",
  "token_type": "Bearer",
  "expires_in": 31536000
}
```



#### 3.3 Error responses

An unsuccessful request will a HTTP status error code and a JSON payload containing an `error` value, for example:

```json
{
  error: "invalid_grant"
}
```



| Error scenario                     | HTTP status          | Error                    |
| :--------------------------------- | :------------------- | :----------------------- |
| Client ID or client secret invalid | `401` (Unauthorized) | `invalid_client`         |
| Grant type is missing              | `400` (Bad Request)  | `invalid_request`        |
| Grant type is invalid              | `400` (Bad Request)  | `unsupported_grant_type` |
| Redirect URI is missing            | `400` (Bad Request)  | `invalid_grant`          |
| Redirect URI is invalid            | `400` (Bad Request)  | `invalid_grant`          |
| Code is missing                    | `400` (Bad Request)  | `invalid_grant`          |
| Code is invalid                    | `400` (Bad Request)  | `invalid_grant`          |
| Code verifier missing              | `400` (Bad Request)  | `invalid_grant`          |
| Code verifier invalid              | `400` (Bad Request)  | `invalid_grant`          |



## Calling the API

You can now call an API using the `access_token` we issued. Do this with an Authorization header containing this `access_token` as an OAuth 2.0 Bearer Token 

##### Example request

```
curl -X GET https://sandbox.register-early-career-teachers/hello/user \
-H "Accept: application/vnd.hmrc.1.0+json" \
-H "Authorization: Bearer [ACCESS-TOKEN]"
```

#### 

(maybe we defer this section until we have the `/hello` API to reference?)



## When an access token expires

When an access token has expired you will be unable to access the API.

You will need to get a new access token by following the authorization process again to obtain a new one.



## Revoking authorisation

You can revoke an authorization should there be a need to do so, for example if the token was leaked.

You revoke a token via a HTTP POST request to our revoke endpoint.

You must authenticate the request with [HTTP Basic Authentication](https://www.rfc-editor.org/info/rfc7617/) using your client ID and secret.  This takes the form of a HTTP header in which you Base64 encode your credentials in the form `client_id:client_secret`.  For example, if your client ID was `client123` and your secret was `supersecretvalue` then your Basic Authentication header would be this:

```
Authorization: Basic Y2xpZW50MTIzOnN1cGVyc2VjcmV0dmFsdWU=
```


>  [!WARNING]
>
>  Do not include your client ID or client secret in the body of the request.

Include the other parameters in the request body, not as additional request headers.

The example URLs shown below are for the sandbox environment only. In the production environment you should use https://register-early-career-teachers.education.gov.uk/

#### Example request

```
curl -X POST https://sandbox.register-early-career-teachers.education.gov.uk/oauth/revoke \
--user "client123:supersecretvalue" \
-H "content-type:application/x-www-form-urlencoded" \
--data "token=[ACCESS-TOKEN-TO-REVOKE]"

```

| Parameter | Description                     |
| :-------- | :------------------------------ |
| `token`   | The access token to be revoked. |

The successful response will be HTTP status 200 code with an empty body.  The access token will now be unusable.



#### Error responses

An unsuccessful request will a HTTP status error code and a JSON payload containing an `error` value, for example:

```json
{
  error: "invalid_client"
}
```

| Error scenario                     | HTTP status          | Error            |
| :--------------------------------- | :------------------- | :--------------- |
| Client ID or client secret invalid | `401` (Unauthorized) | `invalid_client` |


