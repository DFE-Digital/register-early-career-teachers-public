class CreateNotifyOutbounds < ActiveRecord::Migration[8.1]
  def change
    create_table :notify_outbounds do |t|
      t.string :reference, null: false
      t.string :mailer, null: false
      t.string :mailer_action, null: false

      t.timestamps

      t.index :reference, unique: true
    end
  end
end
