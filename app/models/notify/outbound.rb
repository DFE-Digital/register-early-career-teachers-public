class Notify::Outbound < ApplicationRecord
  self.table_name = "notify_outbounds"

  has_one :delivery_receipt,
          class_name: "Notify::DeliveryReceipt",
          inverse_of: :notify_outbound,
          dependent: :restrict_with_error

  validates :reference, presence: true, uniqueness: true
  validates :mailer, presence: true
  validates :mailer_action, presence: true
end
