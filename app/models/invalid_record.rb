# A data source for identifying invalid records captured for analyst triage.
# No foreign keys are needed on this table: `table_name` + `record_id` are
# sufficient for Blazer to surface any entity using smart columns and linked columns.
#
# Queries can alias using AS:
#
# ```sql
#   SELECT record_id AS teacher_id FROM invalid_records WHERE table_name = 'teachers'
# ```
class InvalidRecord < ApplicationRecord
end
