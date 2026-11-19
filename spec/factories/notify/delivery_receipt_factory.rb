FactoryBot.define do
  factory(:notify_delivery_receipt, class: "Notify::DeliveryReceipt") do
    notification_type { "email" }
    recipient { Faker::Internet.email }
    status { "delivered" }

    notification_id { SecureRandom.uuid }
    reference { SecureRandom.uuid }

    requested_at { 5.minutes.ago }
    sent_at { 4.minutes.ago }
    completed_at { 3.minutes.ago }

    template_id { SecureRandom.uuid }
    template_version { 1 }
  end
end
