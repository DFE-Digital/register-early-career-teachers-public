FactoryBot.define do
  factory(:schedule) do
    association :contract_period
    identifier { 'ecf-standard-september' }
  end
end
