---
title: DfE Sign-In
---

Service users of both RECT and RIAB authenticate using DfE Sign-In.

Authentication to the service requires the user to be associated to an organisation
and be granted a sub-service role by their organisation's approver.

See [policies and roles](./dfe-sign-in.md)

### 1. Register ECTs - Schools

If the user enters with an organisation `URN` that matches a school, and has the
`SchoolUser` role, they will be granted access to `Register Early Career Teachers`.

### 2. Record Inductions - Appropriate Bodies

If the user enters with an organisation `UUID` that matches an appropriate body,
and has the `AppropriateBodyUser` role, they will be granted access to `Record Inductions as an Appropriate body`.

### 3. Both

If the user satisfies both 1. and 2. they will default to 1. and can switch context to 2.

