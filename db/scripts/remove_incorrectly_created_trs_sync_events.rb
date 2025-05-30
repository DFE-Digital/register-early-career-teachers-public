# Remove incorrectly created TRS sync events. These happened because of a bug
# in the sync script that meant:
# - teacher_trs_induction_status_updated were created with blank statuses
#   every time the job was run
# - teacher_trs_attributes_updated was created with just the update of
#   the trs_data_last_refreshed_at even if nothing else was changed
#
# As it's only been running for a couple of days we'll clear them all and
# start fresh.
#
# See https://github.com/DFE-Digital/register-early-career-teachers-public/pull/462/ for more
# details
Event.transaction do
  Event.where(event_type: 'teacher_trs_induction_status_updated').delete_all

  # get rid of teacher_trs_attributes_updated events where the modifications length
  # is 98 i.e., this:
  #
  # TRS data last refreshed at changed from '2025-04-11 13:20:31 UTC' to '2025-04-14 04:24:22 UTC'
  #
  # because trs_data_last_refreshed_at will always be present it's the minimum
  Event
    .where(event_type: 'teacher_trs_attributes_updated')
    .where('length(modifications::varchar) = 98')
    .delete_all
end
