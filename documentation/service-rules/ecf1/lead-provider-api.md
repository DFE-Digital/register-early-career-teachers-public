---
title: Lead provider API
---

Lead providers must use this API to view, submit and update participant data so they receive accurate payments from the Department for Education (DfE) for their ECF-based training.

Once a participant has been registered to the service by their school, data associated with them becomes available to lead providers via the API.

## Contents

[API versions and updates](#api-versions-and-updates)

[Financial statements](/service-rules/ecf1/statements)

[How participant declarations works](/service-rules/ecf1/participant-declarations)

## API versioning and updates management

We continuously implement improvements and feature enhancements to the API codebase. Internal teams can reference the <a href="https://manage-training-for-early-career-teachers.education.gov.uk/api-reference/release-notes.html" target="_blank">release notes</a> for detailed changelogs and implementation notes.

Version control is managed through the URL path parameter `/api/v{n}/`. When breaking changes are introduced that affect data structures or endpoint functionality, we increment the version number (e.g., `/api/v1/` to `/api/v2/`). Development teams should prioritize supporting the latest version in all internal systems and tools.

Our versioning policy maintains support for only one previous version when a new version is released. For example, upon `v4` release, `v2` will be deprecated and scheduled for decommissioning according to our standard deprecation timeline.

Exception note: `v1` has an extended support window beyond our standard policy due to ongoing provider transition plans. The Engineering and Provider Relations teams are coordinating this extended support.

Non-breaking changes (backward compatible) are deployed without version increments. These include adding new attributes, extending existing functionality, or performance optimizations that maintain the current contract. These changes are documented in our internal sprint reviews and release notes.
