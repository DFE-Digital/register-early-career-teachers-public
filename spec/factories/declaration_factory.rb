FactoryBot.define do
  factory(:declaration) do
    association :training_period
    declaration_type { 'started' }
  end
end
