class EnsureNotifyDeliveryReceiptsOutboundIdNotNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :notify_delivery_receipts, :notify_outbound_id, false
  end
end
