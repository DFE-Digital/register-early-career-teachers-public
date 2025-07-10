# We introduced `Events::TransitionDescription` as a consistent entrypoint
# for describing transitions between events.
# This brings how we describe Event headings in line with how we describe lists of
# event modifications.
# We need to migrate existing data, though.

# Retrieve all the events with headings that "changed from ''"
#
# Before: "Induction status changed from '' to 'InProgress'"
# After: "Induction status set to 'InProgress'"

Event.where("heading LIKE ?", "%changed from ''%").find_each do |event|
  heading = event.heading.gsub("changed from ''", "set")
  event.update_column(:heading, heading)
end
