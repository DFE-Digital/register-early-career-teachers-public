RSpec.shared_context '2 valid claims' do |_type|
  # 2 valid records
  let(:data) do
    [
      { trn: '1234567', dob: '1981-06-30', induction_programme: 'fip', start_date: '2025-01-30', error: '' },
      { trn: '7654321', dob: '1981-06-30', induction_programme: 'CIP', start_date: '2025-01-30', error: '' }
    ]
  end
end

RSpec.shared_context '3 valid actions' do |_type|
  # 3 valid records
  let(:data) do
    [
      { trn: '1234567', dob: '1981-06-30', number_of_terms: '0.5', end_date: '2025-01-30', objective: 'pass',    error: '' },
      { trn: '7654321', dob: '1981-06-30', number_of_terms: '7.2', end_date: '2025-01-30', objective: 'fail',    error: '' },
      { trn: '0000007', dob: '1981-06-30', number_of_terms: '1',   end_date: '2025-01-30', objective: 'release', error: '' }
    ]
  end
end
