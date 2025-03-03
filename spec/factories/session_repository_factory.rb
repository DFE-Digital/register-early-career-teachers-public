FactoryBot.define do
  factory(:session_repository) do
    skip_create
    initialize_with { new(session: {}, form_key: :main) }
  end
end
