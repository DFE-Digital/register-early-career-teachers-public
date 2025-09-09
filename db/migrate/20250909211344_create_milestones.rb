class CreateMilestones < ActiveRecord::Migration[8.0]
  def change
    create_table :milestones do |t|
      t.references 'schedule', foreign_key: true
      t.enum 'declaration_type', null: false, enum_type: 'declaration_types'
      t.date 'start_date', null: false
      t.date 'milestone_date', null: true
      t.timestamps
    end

    add_index :milestones, %i[schedule_id declaration_type], unique: true
  end
end
