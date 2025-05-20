---
title: Transfers
---

# Transfers

A transfer represents participant changing school or lead provider. Transfer can be a switch to a new school with same lead provider, switch to new school with different lead provider or a partial transfer where only leave is reported.

## API Endpoints

### `GET /api/v3/participants/ecf/transfers`

This endpoint allows you to retrieve list of all ECF participant transfers.

#### Request parameters

| Parameter | Type   | Required | Description                                                                                                    |
| --------- | ------ | -------- | -------------------------------------------------------------------------------------------------------------- |
| filter    | object | No       | Refine participant transfers to return. This consumes a `ListFilter` schema.                                   |
| page      | object | No       | Pagination options to navigate through the list of participant transfers. This consumes a `Pagination` schema. |

#### Filter parameters (`ListFilter`)

| Name          | Type   | Required | Description                                                                                |
| ------------- | ------ | -------- | ------------------------------------------------------------------------------------------ |
| updated_since | string | No       | Return only records that have been updated since this date and time (ISO 8601 date format) |

#### Pagination parameters (`Pagination`)

| Name     | Type    | Required | Description                |
| -------- | ------- | -------- | -------------------------- |
| page     | integer | No       | Page number to return      |
| per_page | integer | No       | Number of records per page |

#### Response (200 OK)

```json
{
  "data": [
    {
      "id": "db3a7848-7308-4879-942a-c4a70ced400a",
      "type": "participant-transfer",
      "attributes": {
        "updated_at": "2021-05-31T02:22:32.000Z",
        "transfers": {
          "training_record_id": "000a97ff-d2a9-4779-a397-9bfd9063072e",
          "transfer_type": "new_provider",
          "status": "complete",
          "leaving": {
            "school_urn": "123456",
            "provider": "Old Institute",
            "date": "2021-05-31"
          },
          "joining": {
            "school_urn": "654321",
            "provider": "New Institute",
            "date": "2021-06-01"
          },
          "created_at": "2021-05-31T02:22:32.000Z"
        }
      }
    }
  ]
}
```

### GET /api/v3/participants/ecf/{id}/transfers

This endpoint allows you to retrieve a single participant’s transfers

#### Request parameters

| Parameter | Type   | Required | Description                    |
| --------- | ------ | -------- | ------------------------------ |
| id        | string | Yes      | The ID of the ECF participant. |

#### Response (200 OK)

```json
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant-transfer",
    "attributes": {
      "updated_at": "2021-05-31T02:22:32.000Z",
      "transfers": [
        {
          "training_record_id": "000a97ff-d2a9-4779-a397-9bfd9063072e",
          "transfer_type": "new_provider",
          "status": "complete",
          "leaving": null,
          "joining": null,
          "created_at": "2021-05-31T02:22:32.000Z"
        }
      ]
    }
  }
}
```

## Transfer Fields

The following describe how the transfer results are generated:

- `id` - is set to `user.id`
- `updated_at` - most recent `updated_at` from leaving or joining induction record, fallback to `user.updated_at`
- `training_record_id` - is set to `participant_profile.id`
- `transfer_type` - `induction_record.induction_programme.partnership.lead_provider` is used to calculate this value
- `status` - if leaving end date or joining start date is in the past it is set to `incomplete`, otherwise `complete`
- `created_at` - set to `leaving_induction_record.created_at`
- `school_urn` - set to `induction_record.induction_programme.school_cohort.school.urn`
- `provider` - set to `induction_record.induction_programme.partnership.lead_provider.name`
- `date` - set to `end_date` for leaving and `start_date` for joining induction record.

## Types of Transfers

### `new_school`

Participant changes to a new school but stays with the same lead provider

```json
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant-transfer",
    "attributes": {
      "updated_at": "2021-05-31T02:22:32.000Z",
      "transfers": [
        {
          "training_record_id": "000a97ff-d2a9-4779-a397-9bfd9063072e",
          "transfer_type": "new_school",
          "status": "complete",
          "leaving": {
            "school_urn": "123456",
            "provider": "Example Institute",
            "date": "2023-09-01"
          },
          "joining": {
            "school_urn": "654321",
            "provider": "Example Institute",
            "date": "2023-09-01"
          },
          "created_at": "2021-05-31T02:22:32.000Z"
        }
      ]
    }
  }
}
```

### `new_provider`

Participant changes to a new school with a different lead provider

```json
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant-transfer",
    "attributes": {
      "updated_at": "2021-05-31T02:22:32.000Z",
      "transfers": [
        {
          "training_record_id": "000a97ff-d2a9-4779-a397-9bfd9063072e",
          "transfer_type": "new_provider",
          "status": "complete",
          "leaving": {
            "school_urn": "123456",
            "provider": "Old Institute",
            "date": "2023-09-01"
          },
          "joining": {
            "school_urn": "654321",
            "provider": "New Institute",
            "date": "2023-09-01"
          },
          "created_at": "2021-05-31T02:22:32.000Z"
        }
      ]
    }
  }
}
```

### `unknown`

Participant is leaving.

```json
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant-transfer",
    "attributes": {
      "updated_at": "2021-05-31T02:22:32.000Z",
      "transfers": [
        {
          "training_record_id": "000a97ff-d2a9-4779-a397-9bfd9063072e",
          "transfer_type": "unknown",
          "status": "complete",
          "leaving": {
            "school_urn": "123456",
            "provider": "Example Institute",
            "date": "2023-09-01"
          },
          "joining": null,
          "created_at": "2021-05-31T02:22:32.000Z"
        }
      ]
    }
  }
}
```

## Transfer States

- `incomplete` - both leaving end date and joining (if set) start date are in the future
- `complete` - both leaving end date and joining (if set) start date are in the past

|                                                   | Leaving Provider     | Leaving Provider                  | Joining Provider     | Joining Provider                  | Same Leaving/Joining Provider | Same Leaving/Joining Provider     |
| ------------------------------------------------- | -------------------- | --------------------------------- | -------------------- | --------------------------------- | ----------------------------- | --------------------------------- |
|                                                   | Participant Response | Transfer Response                 | Participant Response | Transfer Response                 | Participant Response          | Transfer Response                 |
| **Before Transfer**                               | active               | n/a                               | n/a                  | n/a                               | active                        | n/a                               |
| **Old school SIT reports leaver**                 | leaving              | Shows leaving details             | n/a                  | n/a                               | leaving                       | Shows leaving details             |
| **New school SIT reports joiner**                 | leaving              | Shows leaving and joining details | joining              | Shows leaving and joining details | joining                       | Shows leaving and joining details |
| **After transfer (today's date => joining_date)** | left                 | Shows leaving and joining details | active               | Shows leaving and joining details | active                        | Shows leaving and joining details |

## School Induction Tutor (SIT)

Participant transfer is created when SIT report participants as leaving and the new school SIT reports participants as joining.

## Admin User

Admin user is able to see transfer entries in the participants audit log with `School transfer` set to `true`.

## Data Impact and Schema

Participant transfers is dynamically generated using the `Api::V3::ECF::BuildTransfers` service.

Induction record with `induction_status` is set to `leaving` is used for leaving. The next induction record which does not have `induction_status` as `leaving` and has `school_transfer` set to `true` is used for joining.

Take note, old induction records might have incorrect formatting or sequence which could result in the transfer record being incorrect.
