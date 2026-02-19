FactoryBot.define do
  factory :migration_statement_line_item, class: "Migration::StatementLineItem" do
    statement { FactoryBot.create(:migration_statement) }
    participant_declaration { FactoryBot.create(:migration_participant_declaration) }
    state { "submitted" }
  end
end
