---
title: IDs explained
---

We use various unique identifiers (IDs) in the endpoint requests and responses to help make the API reliable, efficient, and unambiguous.

| ID                   | What the ID is for |
|---------------------------|------------------------|
| `clawback_statement_id`   | Identifies a clawback statement we’ve attached when funding paid to a lead provider needs to be returned due to overpayments or participant data changes (for example, someone withdraws from training or is found to be ineligible). Enables lead providers using the declarations endpoints to identify which clawback statement a participant’s funding adjustment relates to and reconcile clawbacks against their monthly or cumulative funding reports. |
| `declaration_id`          | Created when providers submit a declaration. This ID can also be used to void a declaration. It’s shown as simply `id` at the top of successful responses in the declarations endpoints. |
| `delivery_partner_id`     | Identifies delivery partners. Used when providers form partnerships as part of the POST partnerships endpoint. It’s also listed in `GET participants/ecf` and `GET participants/ecf/{id}` responses in API v3. |
| `mentor_id`               | Identifies individual ECT mentors within the API. This ID is used to link mentors to ECTs they’re supporting, and tracks their training status, funding eligibility, and contact information. The same `mentor_id` is used whether the mentor is funded or unfunded, including those trained by a different lead provider than the one supporting their ECT. |
| `participant_id`          | Identifies participants registered for training. This is used for declarations, changing schedules, notifying us of a change in circumstances related to their training as well as other endpoints to monitor training and progress. |
| `participant_id_changes`  | A record of changes where a participant’s ID has been updated, usually to fix a data issue like a duplicate or incorrect registration. In such cases, the `from_participant_id` field is the original ID that has been retired or replaced. The `to_participant_id` is the new ID that should now be used when referring to this participant. |
| `partnership_id`          | Identifies the partnership between schools, delivery partners and providers for a specific cohort who work together to deliver training to participants. It’s shown as simply `id` at the top of successful responses in the partnership endpoints. |
| `statement_id`            | Identifies a financial statement we’ve attached to a lead provider. It acts as a reference for each individual payment cycle or statement and allows lead providers to retrieve financial data using the `GET statements` endpoints. |
| `school_id`               | Identifies schools. Used when providers form partnerships as part of the `POST partnerships` endpoint. |
| `training_record_id`      | Identifies participants with multiple enrolments, such as an ECT who later becomes a mentor. Providers using the participants endpoints will see separate records for the same participant, each with a different `training_record_id` based on their role. |
