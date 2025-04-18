class CreatePendingSchoolJoiners < ActiveRecord::Migration[8.0]
  def change
    create_table :pending_school_joiners do |t|
      t.references :teacher, foreign_key: true
      t.references :school, foreign_key: true
      t.string :role_type, null: false, default: "ect"
      t.date :starting_on, null: false
      t.enum :programme_type, enum_type: :programme_type
      t.references :mentor_at_school_period, foreign_key: true, null: true
      t.references :lead_provider, foreign_key: true, null: true
      t.references :appropriate_body, foreign_key: true, null: true
      t.timestamps
    end
  end
end
