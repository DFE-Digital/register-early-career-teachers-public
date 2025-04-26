FactoryBot.define do
  factory(:pending_induction_submission_batch) do
    association :appropriate_body
    batch_status { 'pending' }
    error_message { nil }
    data { nil }

    trait :claim do
      batch_type { 'claim' }
      data { [{ trn: '1234567', date_of_birth: '1981-06-30', induction_programme: 'fip', start_date: '2025-01-30', error: '' }] }
    end

    trait :action do
      batch_type { 'action' }
      data { [{ trn: '1234567', date_of_birth: '1981-06-30', number_of_terms: '0.5', end_date: '2025-01-30', outcome: 'pass', error: '' }] }
    end
  end
end
