---
title: Authorisation
---

## How authorisation works

We use the open standard [OAuth 2.0](https://oauth.net/2/) with the [Authorization Code Grant](https://oauth.net/2/grant-types/authorization-code/). This standard lets you give your application permission to interact with us without sharing your password.

We use [PKCE](https://oauth.net/2/pkce/), in order to prevent code injection and CSRF attacks in the Authorization Code flow

### Credentials

Your credentials are your client ID and your client secret.

Credentials are used:

- to identify and authorise your application during each step of an OAuth 2.0 journey
- when you test your application with sandbox APIs

### Client ID

Your client ID is a unique identifier we create when we add you to the service.

### Client secrets

Client secrets are unique passphrases that you generate to authorise your application. They are known only to your application and the authorising server.

The client secret is the equivalent of a password and should not be stored in plain text. Only store an encrypted version of the client secret to reduce the chance of it being compromised.



## Before you start



## Access token lifespan

- An access token lasts 1 year.
- When it expires, you can get a new one by going through the authorisation process again. We do not support refresh tokens.

For a working example, see the [user-restricted endpoint tutorial](https://developer.service.hmrc.gov.uk/api-documentation/docs/tutorials#user-restricted).



## Getting an OAuth 2.0 access token

### 1. Create a PKCE code challenge and optional state

### 2. Request authorisation

(we might have to have specifics here, e.g. 'Request authorisation from an Appropriate Body')

### 3. Receive the authorisation result

### 4. Exchange the authorisation code for an access token

### 5. Call the API

(maybe we defer this section until we have the `/hello` API to reference?)

## When an access token expires

## Revoking authorisation
