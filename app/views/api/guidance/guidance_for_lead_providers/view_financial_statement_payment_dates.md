---
title: View financial statement payment dates
sidebar_position: 10
---

Providers can view up-to-date payment cut-off dates, upcoming payment dates, and check to see whether output payments have been made by DfE.

Financial statements are also directly provided to lead providers by DfE and contain the same information, but the below endpoints are available for on-demand requests.

## View all statement payment dates

`GET /api/v3/statements`

For more information on this endpoint, [view the Swagger documentation](https://sandbox.register-early-career-teachers.education.gov.uk/api/docs/v3#/Statements).

## View specific statement payment dates

`GET /api/v3/statements/{id}`

Providers can find statement IDs within [previously submitted declaration](https://sandbox.register-early-career-teachers.education.gov.uk/api/docs/v3#/Declarations) response bodies. This shows which cohort the declaration was made in, which can be helpful to identify when a participant started their training.

This endpoint is also useful when [identifying which cohorts participants have moved between](anchor link to cohort change guidance when published - section about identifying moved ECTs).

For more information on this endpoint, [view the Swagger documentation](https://sandbox.register-early-career-teachers.education.gov.uk/api/docs/v3#/Statements).
