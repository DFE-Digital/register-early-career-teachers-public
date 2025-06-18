FactoryBot.define do
  factory(:pending_induction_submission_batch) do
    pending
    association :appropriate_body
    error_message { nil }
    data { nil }

    trait :claim do
      batch_type { 'claim' }
      data { [{ trn: '1234567', date_of_birth: '1981-06-30', training_programme: 'provider-led', started_on: '2025-01-30' }] }
    end

    trait :action do
      batch_type { 'action' }
      data { [{ trn: '1234567', date_of_birth: '1981-06-30', number_of_terms: '0.5', finished_on: '2025-01-30', outcome: 'pass' }] }
    end
  end
end
