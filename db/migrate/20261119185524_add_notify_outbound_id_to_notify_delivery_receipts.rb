class AddNotifyOutboundIdToNotifyDeliveryReceipts < ActiveRecord::Migration[8.1]
  def change
    add_reference :notify_delivery_receipts, :notify_outbound, foreign_key: true, index: { unique: true }
  end
end
