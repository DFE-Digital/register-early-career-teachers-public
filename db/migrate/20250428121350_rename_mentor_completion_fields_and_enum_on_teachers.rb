class RenameMentorCompletionFieldsAndEnumOnTeachers < ActiveRecord::Migration[8.0]
  def change
    rename_column :teachers, :mentor_completion_date, :mentor_became_ineligible_for_funding_on
    rename_column :teachers, :mentor_completion_reason, :mentor_became_ineligible_for_funding_reason

    rename_enum :mentor_completion_reason, :mentor_became_ineligible_for_funding_reason
  end
end
