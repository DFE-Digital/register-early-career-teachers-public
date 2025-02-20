class AddMentorCompletionReasonToTeachers < ActiveRecord::Migration[8.0]
  def change
    create_enum :mentor_completion_reason, %w[
      completed_declaration_received
      completed_during_early_roll_out
      started_not_completed
    ]

    add_column :teachers, :mentor_completion_reason, :mentor_completion_reason
  end
end
