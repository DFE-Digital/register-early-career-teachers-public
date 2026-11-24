class Notify::DeliveryReceipt < ApplicationRecord
  self.table_name = "notify_delivery_receipts"

  enum :status,
       %w[delivered permanent-failure temporary-failure technical-failure]
        .index_by { it.itself.underscore },
       validate: { message: "Choose a valid status" },
       prefix: true

  enum :notification_type,
       %w[email sms].index_by(&:itself),
       validate: { message: "Choose a valid notification type" },
       prefix: true

  validates :recipient, presence: true
  validates :recipient, notify_email: true, if: :notification_type_email?

  validates :notification_id, presence: true, uniqueness: true

  validates :requested_at, presence: true

  validates :template_id, presence: true
  validates :template_version, numericality: { only_integer: true, greater_than: 0 }

  validate :notification_type_must_be_supported

private

  def notification_type_must_be_supported
    return if notification_type_email?

    errors.add(:notification_type, "Only email notification types are supported")
  end
end
