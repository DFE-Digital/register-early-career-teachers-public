---
title: Syncing data best practice
---

To ensure smooth and reliable integration with the API, it’s important to follow best practice when syncing participant and training data. 

Poor syncing can lead to: 

* payment delays
* conflicting updates
* unnecessary API load 

## Only send what has changed 

Send data only when it has been added, updated, or corrected. 

Repeatedly submitting unchanged records increases the risk of version conflicts or overwriting correct data. For example, if an ECT’s mentor has not changed, lead providers should not re-submit their mentor record with the same details. 

## Use timestamps or status flags to detect changes 

Store and compare: 

* last updated timestamps
* change flags
* status values such as `new`, `updated` and `withdrawn` 

This helps systems detect and sync only what's needed. 

## Rate limits 

Providers are limited to 1,000 requests per 5 minutes when using the API in the production environment. If the limit is exceeded, providers will see `429` HTTP status codes. 

This limit on requests for each authentication key is calculated on a rolling basis. 

## Perform weekly full syncs 

We recommend you sync all records in the API twice a week without using the `updated_since` filters. DfE can coordinate ‘windows’ for providers to do this when the service has a low background load. Contact us if you need further details. 

## Make regular poll requests 

To ensure you never miss any declarations, participants, transfers or unfunded mentors, we recommend making regular poll requests to the relevant `GET endpoints` several times daily. Use the `updated_since` filter and the default pagination of [100] records per page. 

Continue this until the API response is empty. 

### Polling windows 

Always poll 2 windows back from your last successful update request. This guarantees that all participant data is captured. For example: 

* at 3:15pm enter the following request: `/api/v3/participants/ecf?filter[updated_since]=2025-01-28T13:15:00Z`
* at 4:15pm enter the following request: `/api/v3/participants/ecf?filter[updated_since]=2025-01-28T14:15:00Z` 

Try polling randomly rather than on the hour to prevent system overload. 

## Handle API responses and errors properly 

Always log responses and use them to update records. 

If a record fails, providers need to: 

* avoid re-submitting the same bad data
* apply corrections where needed 

For example, if a provider gets a `422 Unprocessable entity` message due to a missing participant ID, they need to fix the local record before reattempting the sync. 

## Avoid common syncing issues

| Issue   | How to avoid it |
| -------------------- | ---------------------- |
| Submitting unchanged records repeatedly | Implement change detection and skip unchanged records | 
| Re-sending withdrawn participants as active | Use clear status tracking and validation before syncing | 
| Syncing large volumes at peak hours | Schedule batch syncs during off-peak hours | 
| Missing required fields | Validate all required data fields locally before submitting |
 
## Test syncing strategy in the sandbox

Before going live, providers should: 

* simulate missed updates 
* test edge cases (for example, mentor swaps, schedule changes) 
* validate their change detection logic 
