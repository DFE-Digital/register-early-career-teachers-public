# Syncing data best practice 

To ensure smooth and reliable integration with the API, it’s important to follow best practice when syncing participant and training data. 

Poor syncing can lead to: 

* duplicated records 
* payment delays 
* conflicting updates 
* unnecessary API load 

## Only send what's changed 

Send data only when it has been added, updated, or corrected. 

Repeatedly submitting unchanged records increases the risk of version conflicts or overwriting correct data. For example, if an ECT’s mentor has not changed, lead providers should not re-submit their mentor record with the same details. 

## Use timestamps or status flags to detect changes 

Store and compare: 

* last updated timestamps 
* change flags 
* status values such as `new`, `updated` and `withdrawn` 

This helps systems detect and sync only what's needed. For example, compare the local `last_updated` timestamp for a participant against the value in their sync logs before deciding to re-send the record. 

## Sync regularly  

Use timed or event-triggered syncs. Avoid real-time syncs unless absolutely necessary. This balances freshness with performance and API limits. 
Schedule a sync once every [X?] hours or after significant updates such as a declaration submission. 

## Handle API responses and errors properly 

Always log responses and use them to update records. 

If a record fails, providers need to: 

* avoid re-submitting the same bad data 
* apply corrections where needed 

For example, if a provider gets a `422 Unprocessable entity` message due to a missing training programme ID, they need to fix the local record before reattempting the sync. 

## Avoid common syncing issues

| Issue   | How to avoid it |
| -------------------- | ---------------------- |
| Submitting unchanged records repeatedly | Implement change detection and skip unchanged records | 
| Re-sending withdrawn participants as active | Use clear status tracking and validation before syncing | 
| Syncing large volumes at peak hours | Schedule batch syncs during off-peak hours | 
| Missing required fields | Validate all required data fields locally before submitting |

## Example: syncing a participant and declaration 

After a participant starts training, lead providers would send: 

```
POST /participants 
{ 
  "full_name": "Joe Bloggs", 
  "start_date": "2025-09-01", 
  "mentor_id": "MENTOR123" 
}
```

Once that’s successfully created, they might later send a declaration: 

```
POST /declarations
{
  "participant_id": "PART123",
  "declaration_type": "started",
  "declaration_date": "2025-09-05"
}
```

If nothing changes after that, no further data is needed until a meaningful update occurs (for example, deferral, reinstatement, mentor change). 
 
## Test syncing strategy in the sandbox

Before going live, providers should: 

* simulate missed updates 
* test edge cases (for example, mentor swaps, schedule changes) 
* validate their change detection logic 
