---
title: View mentoring data
sidebar_position: 16
---

The mentorship endpoints allow lead providers to view mentoring information linked to early career teachers (ECTs) and mentors.

This data helps providers understand mentor relationships and determine what support a mentor may need.

## Which mentoring periods are returned

For an ECT training record, the endpoint returns mentoring periods that are relevant to both the ECT and the provider making the request.

If a provider was never training the ECT while the ECT was at a school, that mentoring period is not returned.

An ECT can only have one active mentoring period at a time. However, an ECT may have multiple mentoring periods throughout their training journey. Each mentoring period is returned separately and has its own status.

Providers should consider all returned mentoring periods when deciding what support a mentor may need.

For example, a mentor:

* with only expired mentoring periods does not require access to a provider's platform to support an ECT
* with expired mentoring periods and a current mentoring period may still require access to support an ECT
* may require access both to support an ECT and to complete their own mentor training

## Mentoring period fields

A mentoring period represents the time an ECT and mentor were linked together.

The mentorship endpoints return the following fields.

| Field | Definition |
| -------- | -------- |
| `uuid` | Unique identifier for the mentoring period |
| `started_on` | Date the mentoring period started |
| `finished_on` | Date the mentoring period ended. This will be `null` for a current mentoring period |
| `updated_at` | Date and time the mentoring period was last updated |
| `school_urn` | URN of the school where the ECT is being mentored |
| `ect_participant_id` | Identifier for the ECT training record |
| `mentor_participant_id` | Identifier for the mentor training record |
| `mentor_email` | Email address recorded for the mentor during the mentoring period |
| `mentor_full_name` | Name recorded for the mentor during the mentoring period |
| `mentorship_status` | Indicates whether a mentor requires access to a provider's platform to support an ECT |
| `mentorship_status_reason` | Explains why a mentoring period has a particular status |

## Mentorship statuses

The `mentorship_status` and `mentorship_status_reason` fields help providers understand what support a mentor may need.

### No access required

A mentoring period with a `mentorship_status` of `no_access_required` means the mentor does not require access to a provider's platform to support the ECT.

This status is used when the `mentorship_status_reason` is `mentorship_expired`.

| Status | Status reason | Definition |
| -------- | -------- | -------- |
| `no_access_required` | `mentorship_expired` | The mentoring period has expired and the mentor does not require access to support the ECT |

### Available to train

A mentoring period with a `mentorship_status` of `available_to_train` means the mentor has ongoing or future training with the provider making the request.

Providers can use participant and participant declaration data to understand more about that training.

| Status | Status reason | Definition |
| -------- | -------- | -------- |
| `available_to_train` | `available_to_train` | The mentor has ongoing or future training with the provider |

### Access and support only

A mentoring period with a `mentorship_status` of `access_and_support_only` means the mentor requires access to a provider's platform to support the ECT.

The value in `mentorship_status_reason` explains why the mentor has this status.

| Status reason | Definition |
| -------- | -------- |
| `completed_training` | The mentor has completed ERO, ECF or ECTP training. This also includes mentors considered fully trained even if they did not receive all 6 ECF declarations |
| `mentor_training_elsewhere` | The mentor is linked to a different provider for training |
| `mentor_not_currently_training` | The mentor has not completed training and may resume training in future |
| `no_known_training_access_only` | The mentor has not been registered for training with any provider while at the school and is not considered to have completed training |
