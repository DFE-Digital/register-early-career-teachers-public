class CreateSupportQueries < ActiveRecord::Migration[8.0]
  def change
    create_table :support_queries do |t|
      t.string :state, null: false, default: "pending"
      t.integer :zendesk_id
      t.string :name, null: false
      t.string :email, null: false
      t.string :school_name, null: false
      t.integer :school_urn, null: false
      t.text :message, null: false

      t.timestamps
    end
  end
end
