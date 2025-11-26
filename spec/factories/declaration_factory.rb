FactoryBot.define do
  factory(:declaration) do
    training_period
    declaration_type { "started" }
  end
end
