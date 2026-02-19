FactoryBot.define do
  factory :migration_participant_band, class: "Migration::ParticipantBand" do
    call_off_contract { FactoryBot.create(:migration_call_off_contract) }
    min { 0 }
    max { 10 }
    per_participant { 100 }
    output_payment_percentage { 60 }
    service_fee_percentage { 40 }
  end
end
