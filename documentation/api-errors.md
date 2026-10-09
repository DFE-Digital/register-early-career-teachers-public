# API errors

## Declarations → Clawback

| Attribute | Message | Cause |
| --- | --- | --- |
| declaration_api_id | The declaration will or has been refunded | When declaration has been clawed back. |
| declaration_api_id | The declaration will or has been refunded | When declaration is awaiting clawback. |
| declaration_api_id | You cannot submit or void declarations for the <contract period year> contract period. The funding contract for this contract period has ended. Get in touch if you need to discuss this with us | When the declaration's payment statement deadline date is in the past. |
| declaration_api_id | You cannot submit or void declarations for the <contract period year> contract period. The funding contract for this contract period has ended. Get in touch if you need to discuss this with us | When the declaration's payment statement has no output fee. |
| declaration_api_id | You cannot submit or void declarations for the <contract period year> contract period. The funding contract for this contract period has ended. Get in touch if you need to discuss this with us | When there are no future output fee statements available. |
| lead_provider_id | Enter a '#/lead_provider_id'. | When lead_provider_id is missing. |
| lead_provider_id | The '#/lead_provider_id' you have entered is invalid. | When lead provider does not exist. |

## Declarations → Create

| Attribute | Message | Cause |
| --- | --- | --- |
| contract_period_year | You cannot submit declarations for the <contract period year> contract period. The funding contract for this contract period has ended. Get in touch if you need to discuss this with us. | When teacher's latest ongoing training period is in a frozen contract period and teacher is eligible for funding. |
| contract_period_year | You cannot submit declarations for the <contract period year> contract period. The funding contract for this contract period has ended. Get in touch if you need to discuss this with us. | When teacher's latest ongoing training period is in a frozen contract period but declaration targets non-frozen. |
| contract_period_year | You cannot submit declarations for the <contract period year> contract period. The funding contract for this contract period has ended. Get in touch if you need to discuss this with us. | When teacher's latest ongoing training period is in a frozen contract period but teacher is not eligible for funding. |
| contract_period_year | You cannot submit or void declarations for the <contract period year> contract period. The funding contract for this contract period has ended. Get in touch if you need to discuss this with us. | When payment statement does not exist. |
| contract_period_year | You cannot submit or void declarations for the <contract period year> contract period. The funding contract for this contract period has ended. Get in touch if you need to discuss this with us. | When payment statement is not open. |
| declaration_type | A declaration has already been submitted that will be, or has been, paid for this event. | When a duplicate declaration already exists. |
| declaration_type | Enter a '#/declaration_type'. | When `declaration_type` is nil. |
| declaration_type | The property '#/declaration_type' does not exist for this schedule. | When milestone does not exist. |
| declaration_type | You cannot send retained or extended declarations for teachers who began their mentor training after June 2025. Resubmit this declaration with either a started or completed declaration. | When declaration type is not started or completed. |
| evidence_type | Enter an available '#/evidence_type' type for this teacher. | When `evidence_type` is invalid for the given `declaration_type`. |
| evidenced_at | Enter a '#/evidenced_at'. | When `evidenced_at` is nil. |
| evidenced_at | Enter a valid RFC3339 '#/evidenced_at'. | When `evidenced_at` is not a date. |
| evidenced_at | Enter a valid RFC3339 '#/evidenced_at'. | When `evidenced_at` is not in the correct format. |
| evidenced_at | Evidenced at must be on or after the milestone start date for the same declaration type. | When evidenced at does not match the milestone start date. |
| evidenced_at | Evidenced at must be on or before the milestone date for the same declaration type. | When declaration date does not match the milestone date. |
| evidenced_at | The '#/evidenced_at' value cannot be a future date. Check the date and try again. | When `evidenced_at` is in the future. |
| evidenced_at | This '#/evidenced_at' is invalid. Check that it is in sequence with existing declaration dates for this teacher. | When contract period is 2025. |
| lead_provider_id | The '#/lead_provider_id' you have entered is invalid. | When the `lead_provider` does not exist. |
| teacher_api_id | This teacher withdrew from this course on <datetime>. Enter a '#/evidenced_at' that's on or before the withdrawal date. | When teacher withdrew before the declaration date. |
| teacher_api_id | Your update cannot be made as the '#/teacher_api_id' is not recognised. Check teacher details and try again. | When a matching training period does not exist (different lead provider). |
| teacher_api_id | Your update cannot be made as the '#/teacher_api_id' is not recognised. Check teacher details and try again. | When the teacher does not exist. |
| teacher_type | Enter a '#/teacher_type'. | When a nil teacher type is provided. |
| teacher_type | Enter a '#/teacher_type'. | When an empty teacher type is provided. |
| teacher_type | The entered '#/teacher_type' is not recognised for the given teacher. Check details and try again. | When a matching training period does not exist (different teacher type). |
| teacher_type | The entered '#/teacher_type' is not recognised for the given teacher. Check details and try again. | When a non-existent teacher type is provided. |

## Declarations → Void

| Attribute | Message | Cause |
| --- | --- | --- |
| declaration_api_id | The declaration has already been voided. | When declaration is voided. |
| declaration_api_id | This declaration has been clawed-back, so you can only view it. | When declaration is paid. |
| lead_provider_id | Enter a '#/lead_provider_id'. | When lead_provider_id is missing. |
| lead_provider_id | The '#/lead_provider_id' you have entered is invalid. | When lead provider does not exist. |

## Teachers → ChangeSchedule

| Attribute | Message | Cause |
| --- | --- | --- |
| contract_period_year | You cannot change a teacher to this contract_period as you do not have a partnership with the school for the contract_period. Contact the DfE for assistance. | When changing contract_period_year without a school partnership. |
| contract_period_year | You cannot move a teacher to a payments frozen contract period unless they previously belonged to that contract period. | When moving to a frozen contract period where the teacher has not been before. |
| lead_provider_id | The '#/lead_provider_id' you have entered is invalid. | When the `lead_provider` does not exist. |
| schedule_identifier | Mentors cannot be placed on a reduced schedule. Assign them to a different schedule. | When a mentor attempts to change to a reduced schedule. |
| schedule_identifier | Mentors cannot be placed on a reduced schedule. Assign them to a different schedule. | When teacher has completed training. |
| schedule_identifier | Selected schedule is already on the profile | When changing to the same schedule. |
| schedule_identifier | Selected schedule is not valid for the teacher_type | When an ECT attempts to change to a replacement schedule. |
| schedule_identifier | The change of schedule cannot be applied because a previous change of schedule and a declaration were made on the same day. Applying another change of schedule would invalidate existing declarations. Please contact DfE for assistance. | When the training period `started_on` has not yet passed and there are existing declarations. |
| schedule_identifier | The property '#/schedule_identifier' must be present and correspond to a valid schedule. | When schedule does not exist. |
| teacher_api_id | Cannot perform actions on a withdrawn teacher | When training_period is withdrawn. |
| teacher_api_id | You cannot change this teacher's schedule as they are due to start with another lead provider in the future. | When there are future training periods (for the same teacher). |
| teacher_api_id | You cannot change this teacher's schedule as they have completed their training or induction. | When teacher has completed training. |
| teacher_api_id | You cannot change this teacher's schedule. This is because the teacher has a 'left' teacher_status, so they are not training with you currently. | When the teacher has left. |
| teacher_api_id | You cannot change this teacher's schedule. This is because the teacher has a 'left' teacher_status, so they are not training with you currently. | When training_period is withdrawn. |
| teacher_api_id | Your update cannot be made as the '#/teacher_api_id' is not recognised. Check teacher details and try again. | When the teacher does not exist. |
| teacher_type | Enter a '#/teacher_type'. | When a nil teacher type is provided. |
| teacher_type | Enter a '#/teacher_type'. | When an empty teacher type is provided. |
| teacher_type | The entered '#/teacher_type' is not recognised for the given teacher. Check details and try again. | When a matching training period does not exist (different lead provider). |
| teacher_type | The entered '#/teacher_type' is not recognised for the given teacher. Check details and try again. | When a matching training period does not exist (different teacher type). |
| teacher_type | The entered '#/teacher_type' is not recognised for the given teacher. Check details and try again. | When a non-existent teacher type is provided. |
| teacher_type | The entered '#/teacher_type' is not recognised for the given teacher. Check details and try again. | When the contract_period_year is not specified and the teacher_type is invalid. |

## Teachers → Defer

| Attribute | Message | Cause |
| --- | --- | --- |
| lead_provider_id | The '#/lead_provider_id' you have entered is invalid. | When the `lead_provider` does not exist. |
| reason | The entered '#/reason' is not recognised for the given teacher. Check details and try again. | When reason is invalid. |
| reason | The entered '#/reason' is not recognised for the given teacher. Check details and try again. | When reason is underscored. |
| teacher_api_id | The '#/teacher_api_id' is already deferred. | When teacher already deferred. |
| teacher_api_id | The '#/teacher_api_id' is already withdrawn. | When teacher already withdrawn. |
| teacher_api_id | You cannot defer #/teacher_api_id. This is because they have not been training with you for at least one day. | When training not started yet. |
| teacher_api_id | You cannot defer or withdraw this teacher today. You need to try again tomorrow as the training was recently changed for this teacher. | When training started today. |
| teacher_api_id | Your update cannot be made as the '#/teacher_api_id' is not recognised. Check teacher details and try again. | When the teacher does not exist. |
| teacher_type | Enter a '#/teacher_type'. | When a nil teacher type is provided. |
| teacher_type | Enter a '#/teacher_type'. | When an empty teacher type is provided. |
| teacher_type | The entered '#/teacher_type' is not recognised for the given teacher. Check details and try again. | When a matching training period does not exist (different lead provider). |
| teacher_type | The entered '#/teacher_type' is not recognised for the given teacher. Check details and try again. | When a matching training period does not exist (different teacher type). |
| teacher_type | The entered '#/teacher_type' is not recognised for the given teacher. Check details and try again. | When a non-existent teacher type is provided. |

## Teachers → Resume

| Attribute | Message | Cause |
| --- | --- | --- |
| lead_provider_id | The '#/lead_provider_id' you have entered is invalid. | When the `lead_provider` does not exist. |
| teacher_api_id | The '#/teacher_api_id' is already active. | When teacher training period is active/ongoing. |
| teacher_api_id | The teacher is no longer at the school. Please contact the induction tutor to resolve. | When at school period is finished. |
| teacher_api_id | The teacher is no longer at the school. Please contact the induction tutor to resolve. | When the school period finishes today, but the training period finished before today. |
| teacher_api_id | This teacher cannot be resumed because they are already active with another provider. | When there is another active/ongoing training period for the school period at a different lead provider. |
| teacher_api_id | This teacher cannot be resumed because they are already active with another provider. | When there is another active/ongoing training period that finishes in the future for the school period at a different lead provider. |
| teacher_api_id | You cannot resume a teacher on the same day they were withdrawn or deferred. Resume them tomorrow or later. | When training period has finished today. |
| teacher_api_id | Your update cannot be made as the '#/teacher_api_id' is not recognised. Check teacher details and try again. | When the teacher does not exist. |
| teacher_type | Enter a '#/teacher_type'. | When a nil teacher type is provided. |
| teacher_type | Enter a '#/teacher_type'. | When an empty teacher type is provided. |
| teacher_type | The entered '#/teacher_type' is not recognised for the given teacher. Check details and try again. | When a matching training period does not exist (different lead provider). |
| teacher_type | The entered '#/teacher_type' is not recognised for the given teacher. Check details and try again. | When a matching training period does not exist (different teacher type). |
| teacher_type | The entered '#/teacher_type' is not recognised for the given teacher. Check details and try again. | When a non-existent teacher type is provided. |

## Teachers → Withdraw

| Attribute | Message | Cause |
| --- | --- | --- |
| lead_provider_id | The '#/lead_provider_id' you have entered is invalid. | When the `lead_provider` does not exist. |
| reason | The entered '#/reason' is not recognised for the given teacher. Check details and try again. | When reason is invalid. |
| reason | The entered '#/reason' is not recognised for the given teacher. Check details and try again. | When reason is underscored. |
| reason | You cannot withdraw an ECT for this reason. The ECT is not a mentor. | When ECT has a mentor-no-longer-being-mentor reason. |
| teacher_api_id | The '#/teacher_api_id' is already withdrawn. | When teacher already withdrawn. |
| teacher_api_id | You cannot defer or withdraw this teacher today. You need to try again tomorrow as the training was recently changed for this teacher. | When training started today. |
| teacher_api_id | You cannot withdraw #/teacher_api_id. This is because they have not been training with you for at least one day. | When training not started yet. |
| teacher_api_id | Your update cannot be made as the '#/teacher_api_id' is not recognised. Check teacher details and try again. | When the teacher does not exist. |
| teacher_type | Enter a '#/teacher_type'. | When a nil teacher type is provided. |
| teacher_type | Enter a '#/teacher_type'. | When an empty teacher type is provided. |
| teacher_type | The entered '#/teacher_type' is not recognised for the given teacher. Check details and try again. | When a matching training period does not exist (different lead provider). |
| teacher_type | The entered '#/teacher_type' is not recognised for the given teacher. Check details and try again. | When a matching training period does not exist (different teacher type). |
| teacher_type | The entered '#/teacher_type' is not recognised for the given teacher. Check details and try again. | When a non-existent teacher type is provided. |