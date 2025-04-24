# Rename induction period events to their new names as part of the event naming
# standardization effort.
#
# See:
# - https://github.com/DFE-Digital/register-early-career-teachers-public/issues/420
# - https://github.com/DFE-Digital/register-early-career-teachers-public/issues/426
# - https://github.com/DFE-Digital/register-early-career-teachers-public/issues/432
# - https://github.com/DFE-Digital/register-early-career-teachers-public/issues/474
# - https://github.com/DFE-Digital/register-early-career-teachers-public/issues/475

Event.transaction do
  # Admin events
  Event
    .where(event_type: 'admin_creates_induction_period')
    .update_all(event_type: 'induction_period_opened')

  Event
    .where(event_type: 'admin_updates_induction_period')
    .update_all(event_type: 'induction_period_updated')

  Event
    .where(event_type: 'admin_fails_teacher_induction')
    .update_all(event_type: 'teacher_fails_induction')

  Event
    .where(event_type: 'admin_passes_teacher_induction')
    .update_all(event_type: 'teacher_passes_induction')

  Event
    .where(event_type: 'admin_reverts_teacher_claim')
    .update_all(event_type: 'teacher_induction_status_reset')

  Event
    .where(event_type: 'admin_deletes_induction_period')
    .update_all(event_type: 'induction_period_deleted')

  # Appropriate body events
  Event
    .where(event_type: 'appropriate_body_claims_teacher')
    .update_all(event_type: 'induction_period_opened')

  Event
    .where(event_type: 'appropriate_body_releases_teacher')
    .update_all(event_type: 'induction_period_closed')

  Event
    .where(event_type: 'appropriate_body_fails_teacher')
    .update_all(event_type: 'teacher_fails_induction')

  Event
    .where(event_type: 'appropriate_body_passes_teacher')
    .update_all(event_type: 'teacher_passes_induction')

  Event
    .where(event_type: 'appropriate_body_updates_induction_extension')
    .update_all(event_type: 'induction_extension_updated')

  Event
    .where(event_type: 'appropriate_body_adds_induction_extension')
    .update_all(event_type: 'induction_extension_created')

  # TRS events
  Event
    .where(event_type: 'teacher_induction_status_updated_by_trs')
    .update_all(event_type: 'teacher_trs_induction_status_updated')

  Event
    .where(event_type: 'teacher_attributes_updated_from_trs')
    .update_all(event_type: 'teacher_trs_attributes_updated')
end
