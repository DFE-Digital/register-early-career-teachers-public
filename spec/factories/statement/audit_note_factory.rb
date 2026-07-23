FactoryBot.define do
  factory(:statement_audit_note, class: "Statement::AuditNote") do
    statement

    sequence(:body) { |n| "Audit note #{n}" }
  end
end
