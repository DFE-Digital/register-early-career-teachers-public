RSpec.shared_context '2 valid claims' do
  let(:file_name) do
    '2 valid claims.csv'
  end

  let(:data) do
    [
      { trn: '1234567', date_of_birth: '1981-06-30', induction_programme: 'fip', started_on: '2025-01-30', error: '' },
      { trn: '7654321', date_of_birth: '1981-06-30', induction_programme: 'CIP', started_on: '2025-01-30', error: '' }
    ]
  end
end

RSpec.shared_context '3 valid actions' do
  let(:file_name) do
    '3 valid actions.csv'
  end

  let(:data) do
    [
      { trn: '1234567', date_of_birth: '1981-06-30', number_of_terms: '0.5', finished_on: '2025-01-30', outcome: 'pass',    error: '' },
      { trn: '7654321', date_of_birth: '1981-06-30', number_of_terms: '7.2', finished_on: '2025-01-30', outcome: 'fail',    error: '' },
      { trn: '0000007', date_of_birth: '1981-06-30', number_of_terms: '1',   finished_on: '2025-01-30', outcome: 'release', error: '' }
    ]
  end
end
