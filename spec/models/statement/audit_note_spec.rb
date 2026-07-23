describe Statement::AuditNote do
  describe "associations" do
    it { is_expected.to belong_to(:statement) }
  end

  describe "validations" do
    subject { FactoryBot.create(:statement_audit_note) }

    it { is_expected.to validate_presence_of(:body).with_message("Enter the audit note text") }
  end
end
