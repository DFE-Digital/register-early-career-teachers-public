---
title: How to test the API effectively
---

## Before starting 

Bookmark the [Swagger API documentation](/api/docs/v3). It includes: 

* a list of all available API endpoints
* required data fields and formats
* response types and error messages 

Read our [guidance on keeping data in sync](/api/guidance/guidance-for-lead-providers/keeping-data-in-sync).

## Test in the sandbox

Use the [sandbox environment](https://sandbox.register-early-career-teachers.education.gov.uk/api/) to test API integrations without affecting real data. 

Try each operation individually before automating. 

## API rate limit restrictions in Sandbox

The API is limited to 1,000 requests every 5 minutes for authenticated requests, and 300 every 5 minutes for unauthenticated requests.

Please contact us if this causes an issue.

## Focused pulls 

Avoid pulling everything every time. 
 
Instead of downloading all schools, participants, or partnerships on every test run, focus on specific endpoints or filters that match your integration logic. 
 
### Example 

Try using `GET /participants?filter[updated_since]=2025-10-01T00:00:00Z` instead of pulling the entire participant list every time. 

## Test different values for fields in endpoints 

Make sure you test how your system behaves with every possible field value, not just the ones you expect. 

### Example 

Try a participant with `training_status = deferred` to check your code handles all cases safely. 

## Test error handling (make failures on purpose) 

Don’t just test the happy paths. Force some errors to see how your integration responds. 
 
### Example 

Submit a partnership with missing data to trigger a `422 error`, and confirm your system logs it properly and doesn’t crash or retry endlessly. 

## Test for order or uniqueness 

Check how your system handles repeated data or changing order in API responses. 

Contact us if the same participant appears twice in a page of results. There should not be any duplicates. 

## Test pagination with default value of 100 per page 

By default, the API returns up to 100 items per page. You need to test fetching multiple pages. 
 
### Example 

Try calling `GET /participants?page[per_page]=100&page[page]=2` to make sure your system correctly follows pagination links and doesn’t stop after the first batch.

## Test declaration submissions using X-With-Server-Date

`X-With-Server-Date` is a custom JSON header supported in the sandbox environment. It lets you test your integrations and ensure you're able to submit declarations for future milestone dates.

The `X-With-Server-Date` header lets you simulate future dates, and therefore allows you to test declaration submissions for future milestone dates.

It's only valid in the sandbox environment. Attempts to submit future declarations in the production environment (or without this header in sandbox) will be rejected as part of milestone validation.

### How to use the header

To test declaration submission functionality, include:

- the header `X-With-Server-Date` as part of your declaration submission request
- the value of your chosen date in ISO8601 Date with time and Timezone (RFC3339 format)

For example:

```
X-With-Server-Date: 2025-01-10T10:42:00Z
```

### Response

Successful requests will return a response body including updates to the declaration state, which will become:

- `voided` if it had been `submitted`, `ineligible`, `eligible`, or `payable`
- `awaiting_clawback` if it had been `paid`

[View more information on declaration states](https://manage-training-for-early-career-teachers.education.gov.uk/api-reference/ecf/definitions-and-states/#declaration-states).

## Check seed data is adequate or request seed data that’s more tailored to your needs 

Make sure the test data (seed data) in the sandbox fits what you need to test. If it doesn’t, ask DfE for adjustments. 

### Example 

If you only see one school or cohort, request extra records so you can test multiple partnerships or transfers. 

## Use the header which allows you to perform actions in the future for testing correctly (`X-With-Server-Date`) 

Use the `X-With-Server-Date` header to simulate future dates when testing time-sensitive features. 

### Example 

To test what happens after a participant leaves training, send the header `X-With-Server-Date: 2025-12-31` so the system behaves as if it’s the end of the year. 

## Try to `POST` every type of declaration for a participant 
Don’t just test one declaration type, try them all to make sure your system handles different scenarios. 

### Example 

Test posting `started`, `retained-1`, and `completed` declarations for the same participant so you can check the logic for each training milestone works correctly. 

## Testing checklist 

Use this checklist to confirm your integration works correctly and securely:

- all standard processes for partnerships, participants, and declarations work as expected
- error paths have been tested successfully
- both full syncs (all records) and partial syncs (only new or updated records using the `updated_since` filter) have been implemented
- multiple partnerships per school/cohort supported
- new fields such as `expression_of_interest` and `participants_currently_training` work correctly
- access keys secured
- sandbox tests recorded with sample requests, responses and timestamps
