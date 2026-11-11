---
title: View mentoring data
sidebar_position: 11
---

<div class="govuk-notification-banner" role="region" aria-labelledby="govuk-notification-banner-title" data-module="govuk-notification-banner">
  <div class="govuk-notification-banner__header">
    <h2 class="govuk-notification-banner__title" id="govuk-notification-banner-title">
      Important
    </h2>
  </div>
  <div class="govuk-notification-banner__content">
    <p class="govuk-notification-banner__heading">
      The mentorship endpoints described in this guidance are currently available for testing in the sandbox environment only. They are not available in production.
    </p>

The mentorship endpoints allow lead providers to view mentoring information linked to early career teachers (ECTs) and mentors.

This data helps providers understand mentor relationships and determine what support a mentor may need.

## Retrieve multiple mentoring periods

Providers can use the `GET /mentorships` endpoint to retrieve mentorship periods.

The endpoint supports the following filters.

| Filter | Definition |
| -------- | -------- |
| `role` | Filter mentorship periods by participant role |
| `updated_since` | Return only mentorship periods updated since the specified date |

## Retrieve a participant's mentoring periods

Providers can use the `GET /participants/:id/mentorships` endpoint to retrieve all mentoring periods for a specific participant.

The `role` and `updated_since` filters can also be applied when using this endpoint.

## Which mentoring periods are returned

For an ECT training record, the endpoint returns mentoring periods that are relevant to both the ECT and the provider making the request.

If a provider was never training the ECT while the ECT was at a school, that mentoring period is not returned.

An ECT can only have one active mentoring period at a time. However, an ECT may have multiple mentoring periods throughout their training journey. Each mentoring period is returned separately and has its own status.

Providers should consider all returned mentoring periods when deciding what support a mentor may need.

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
| `ect_participant_id` | Identifier for the ECT participant. This matches the `id` returned by the participant endpoint |
| `mentor_participant_id` | Identifier for the mentor participant. This matches the `mentor_id` returned by the participant endpoint |
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
| `no_access_required` | `mentorship_expired` | The mentor no longer requires access to the provider's platform to support the ECT because the mentoring period has ended |

A mentor may still require access to a provider's platform if they have another current mentoring period supporting a different ECT. Providers should consider all mentoring periods returned for a mentor before deciding what access the mentor requires.

### Available to train

A mentoring period with a `mentorship_status` of `available_to_train` means the mentor has ongoing or future training with the provider making the request.

Providers can use participant and participant declaration data to understand more about that training.

| Status | Status reason | Definition |
| -------- | -------- | -------- |
| `available_to_train` | `available_to_train` | The mentor has ongoing or future training with the provider |

### Access and support only

A mentoring period with a `mentorship_status` of `access_and_support_only` means the mentor requires access to a provider's platform to support the ECT.

The value in `mentorship_status_reason` explains why the mentor has this status.

A mentor may have multiple mentoring periods with different statuses. Providers should consider all mentoring periods returned for a mentor when deciding what support or platform access the mentor requires.

| Status reason | Definition |
| -------- | -------- |
| `completed_training` | The mentor has completed ERO, ECF or ECTP training, including mentors who are considered fully trained even if they did not receive all 6 ECF declarations |
| `mentor_training_elsewhere` | The mentor is currently training with a different provider |
| `mentor_not_currently_training` | The mentor has not completed training and is not currently training with a provider, but may resume training in the future |
| `no_known_training` | The mentor is not known to have trained with any provider while at the school and is not considered to have completed training |

If a mentor has a status reason of `mentor_training_elsewhere` and the school wants the mentor to train with the same provider as the ECT, the lead provider must ask the school's induction tutor to update the mentor's lead provider in Register early career teachers (RECT). Once this has been done, the mentor's training details will be available through the API.

If a mentor has a status reason of `mentor_not_currently_training`, the provider can resume the mentor's training using the `PUT /resume` endpoint. Before doing this, the provider should check that the mentor is visible in the `GET /participants` response and has a status of deferred or withdrawn.
