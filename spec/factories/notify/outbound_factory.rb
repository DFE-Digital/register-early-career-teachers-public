FactoryBot.define do
  factory(:notify_outbound, class: "Notify::Outbound") do
    reference { SecureRandom.uuid }

    mailer { "Schools::ECTRegistrationMailer" }
    mailer_action { "school_led_confirmation" }

    trait :with_delivery_receipt do
      after(:build) do |notify_outbound|
        notify_outbound.delivery_receipt = build(:notify_delivery_receipt, notify_outbound:)
      end
    end
  end
end
