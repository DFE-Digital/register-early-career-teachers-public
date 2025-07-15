RSpec.shared_context '2 valid claims' do
  let(:file_name) { '2 valid claims.csv' }

  let(:data) do
    [
      { trn: '1234567', date_of_birth: '1981-06-30', training_programme: 'PROVIDER-LED', started_on: '2025-01-30' },
      { trn: '7654321', date_of_birth: '1981-06-30', training_programme: 'school-led', started_on: '2025-01-30' }
    ]
  end
end

RSpec.shared_context '1 valid and 1 invalid claim' do
  include_context '2 valid claims'

  let(:file_name) { '1 valid 1 invalid claim.csv' }

  before do
    already_claimed_teacher = FactoryBot.create(:teacher, trn: '1234567')
    FactoryBot.create(:induction_period, :active, teacher: already_claimed_teacher)
  end
end

RSpec.shared_context '3 valid actions' do
  let(:file_name) { '3 valid actions.csv' }

  let(:data) do
    [
      { trn: '1234567', date_of_birth: '1981-06-30', number_of_terms: '0.5', finished_on: '2025-01-30', outcome: 'pass' },
      { trn: '7654321', date_of_birth: '1981-06-30', number_of_terms: '7.2', finished_on: '2025-01-30', outcome: 'fail' },
      { trn: '0000007', date_of_birth: '1981-06-30', number_of_terms: '1',   finished_on: '2025-01-30', outcome: 'release' }
    ]
  end

  before do
    data.map do |row|
      teacher = FactoryBot.create(:teacher, trn: row[:trn])
      FactoryBot.create(:induction_period, :active, teacher:, appropriate_body:, started_on: '2024-12-01')
    end
  end
end

RSpec.shared_context '1 valid and 2 invalid actions' do
  let(:file_name) { '1 valid 2 invalid actions.csv' }

  let(:data) do
    [
      { trn: '1234567', date_of_birth: '1981-06-30', number_of_terms: '0.5', finished_on: '2025-01-30', outcome: 'pass' },
      { trn: '7654321', date_of_birth: '1981-06-30', number_of_terms: '7.2', finished_on: '2025-01-30', outcome: 'fail' },
      { trn: '0000007', date_of_birth: '1981-06-30', number_of_terms: '1',   finished_on: '2025-01-30', outcome: 'release' }
    ]
  end

  before do
    valid_teacher = FactoryBot.create(:teacher, trn: '1234567')
    FactoryBot.create(:induction_period, :active, teacher: valid_teacher, appropriate_body:, started_on: '2024-12-01')
    teacher_at_another_body = FactoryBot.create(:teacher, trn: '7654321')
    FactoryBot.create(:induction_period, :active, teacher: teacher_at_another_body, started_on: '2024-12-01')
    FactoryBot.create(:teacher, trn: '0000007')
  end
end
