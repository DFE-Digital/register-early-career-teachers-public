# Remove blank teacher_trs_attributes_updated events
#
# We recorded events where the modifications hash was empty which adds noise
# to timelines. The fix was made in #471 and this script will clear out the
# empty events

Event.transaction do
  # Empty JSON object when converted to varchar is '{}'
  Event
    .where(event_type: 'teacher_trs_attributes_updated')
    .where('length(modifications::varchar) = 2')
    .delete_all
end
