# How to test the API effectively 

## Start in sandbox 

Use the [sandbox environment](/api)  to test API integrations without affecting real data. 

Read the [Swagger documentation](/api/docs/v3) and try each operation individually before automating. 

## Focused pulls 

Avoid pulling everything every time. 
 
Instead of downloading all schools, participants, or partnerships on every test run, focus on specific endpoints or filters that match your integration logic. 
 
### Example 

Use `GET /participants?filter[updated_since]=2025-10-01T00:00:00Z` instead of pulling the entire participant list every time. 

## Perform weekly syncs 

We recommend you sync all records in the API weekly without using the `updated_since` filters. We can coordinate ‘windows’ for providers to do this when the service has a low background load. Contact us if you need further details. 

## Poll daily 

To ensure you never miss any declarations, participants, transfers or unfunded mentors, we recommend making regular poll requests to the relevant `GET` endpoints several times daily. Use the `updated_since` filter and the default pagination of [100] records per page. 

Continue this until the API response is empty. 

### Polling windows 

Always poll 2 windows back from your last successful update request. This guarantees that all participant data is captured. For example: 

* at 3:15pm enter the following request - `/api/v3/participants/ecf?filter[updated_since]=2025-01-28T13:15:00Z`
* at 4:15pm enter the following request - `/api/v3/participants/ecf?filter[updated_since]=2025-01-28T14:15:00Z` 

Try polling randomly rather than on the hour to prevent system overload. 

## Don't overload the API with too many requests 

Providers are limited to 1,000 requests per 5 minutes when using the API in the sandbox environment. If the limit is exceeded, providers will see `429 HTTP` status codes. 

This limit on requests for each authentication key is calculated on a rolling basis. 

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

### Example 

If the same participant appears twice in a page of results, your sync process should merge them, not duplicate them. Don’t assume results will always come in the same order. 

## Test pagination with default value of 100 per page 

By default, the API returns up to 100 items per page. You need to test fetching multiple pages. 
 
### Example 

Try calling `GET /participants?page[size]=100&page[number]=2` to make sure your system correctly follows pagination links and doesn’t stop after the first batch. 

## Check seed data is adequate or requesting seed data that’s more tailored to their needs 

Make sure the test data (seed data) in the sandbox fits what you need to test. If it doesn’t, ask DfE for adjustments. 

### Example 

If you only see one school or cohort, request extra records so you can test multiple partnerships or transfers. 

## Use the header which allows them to perform actions in the future for testing correctly (`X-With-Server-Date`) 

Use the `X-With-Server-Date` header to simulate future dates when testing time-sensitive features. 

### Example 

To test what happens after a participant leaves training, send the header `X-With-Server-Date: 2025-12-31` so the system behaves as if it’s the end of the year. 

## Try to `POST` every type of declaration for a participant 
Don’t just test one declaration type, try them all to make sure your system handles different scenarios. 

### Example 

Test posting `started`, `retained-1`, and `completed` declarations for the same participant so you can check the logic for each training milestone works correctly. 

## Testing checklist 

- [ ] Happy paths pass for partnerships, participants, and declarations 
- [ ] Error paths handled with retries/back-off where appropriate 
- [ ] Incremental sync implemented. No full-table pulls 
- [ ] Idempotent create/update flows proven by repeat runs 
- [ ] Multiple partnerships per school/cohort supported 
- [ ] Uses `expression_of_interest` and `participants_currently_training` correctly in dashboards 
- [ ] Logs, metrics and alerts in place 
- [ ] Correlation IDs captured 
- [ ] Access keys secured 
- [ ] Sandbox tests recorded with sample requests, responses and timestamps 
