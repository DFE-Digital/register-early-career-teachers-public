class CreateParticipantIdChanges < ActiveRecord::Migration[8.0]
  def change
    create_table :participant_id_changes do |t|
      t.references :teacher, null: false, foreign_key: true
      t.references :from_participant, null: false, type: :uuid, foreign_key: { to_table: :teachers, primary_key: :ecf_user_id }
      t.references :to_participant, null: false, type: :uuid, foreign_key: { to_table: :teachers, primary_key: :ecf_user_id }
      t.uuid :api_id, null: false, default: -> { "gen_random_uuid()" }, index: { unique: true }

      t.timestamps
    end
  end
end
