class CreateNotifyDeliveryReceipts < ActiveRecord::Migration[8.1]
  def change
    create_enum :notify_delivery_receipt_status,
                %w[delivered permanent-failure temporary-failure technical-failure]
    create_enum :notify_delivery_receipt_notification_type,
                %w[email sms]

    create_table :notify_delivery_receipts do |t|
      t.uuid :notification_id, null: false
      t.string :recipient, null: false
      t.enum :status, enum_type: "notify_delivery_receipt_status", null: false
      t.datetime :requested_at, null: false
      t.datetime :completed_at
      t.datetime :sent_at
      t.enum :notification_type, enum_type: "notify_delivery_receipt_notification_type", null: false
      t.uuid :template_id, null: false
      t.integer :template_version, null: false

      t.timestamps

      t.index :notification_id, unique: true
    end
  end
end
