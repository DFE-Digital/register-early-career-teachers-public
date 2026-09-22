---
title: How to use this API
---

## What this section is for

Advice on how best to use the API.

Includes:

* info on getting started
* guidance on what to use the API for
* recommended ways to use the API
* performance tips
* usage patterns
* security recommendations
* versioning and deprecation advice
* common pitfalls
* glossary of technical and policy-specific terminology (TBC)

## View financial statement payment dates

Lead providers can view up-to-date payment cut-off dates, upcoming payment dates, and check to see whether we've made output payments to them.

### View all statement payment dates

GET `/api/v3/statements`

[See technical details for this endpoint](LINK TO SWAGGER DOCUMENTATION)

#### Example response body

`
{
  "data": [
    {
      "id": "cd3a12347-7308-4879-942a-c4a70ced400a",
      "type": "statement",
      "attributes": {
        "month": "May",
        "year": "2025",
        "cohort": "2024",
        "cut_off_date": "2025-04-30",
        "payment_date": "2025-05-25",
        "paid": true
        "created_at": "2024-05-31T02:22:32.000Z",
        "updated_at": "2024-05-31T02:22:32.000Z"
      }
    }
  ]
}
`

### View specific statement payment dates

GET `/api/v3/statements/{id}`

[See technical details for this endpoint](LINK TO SWAGGER DOCUMENTATION)

#### Example response body

`
{
  "data": {
    "id": "cd3a12347-7308-4879-942a-c4a70ced400a",
    "type": "statement",
    "attributes": {
      "month": "May",
      "year": "2025",
      "cohort": "2024",
      "cut_off_date": "2025-04-30",
      "payment_date": "2025-05-25",
      "paid": true,
      "created_at": "2024-05-31T02:22:32.000Z",
      "updated_at": "2024-05-31T02:22:32.000Z"
    }
  }
}
`

